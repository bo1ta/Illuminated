//
//  ProjectMView.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import "ProjectMView.h"
#import <Cocoa/Cocoa.h>
#import <OpenGL/gl3.h>
#import <projectM-4/playlist.h>
#import <projectM-4/playlist_items.h>
#import <projectM-4/playlist_playback.h>
#import <projectM-4/projectM.h>
#import "ProjectMPresetBlacklist.h"

#pragma mark - Constants

static const double kMaxCPUThreshold = 70.0;
static const double kSecondsUntilPresetIsProblematic = 3.0;

static const float kBlackScreenMaxPercentage = 0.95f;
static const NSUInteger kMaxBlackFramesBeforeSkip = 60;

#pragma mark - Private Interface

@interface ProjectMView () {
  projectm_handle _pmHandle;
  projectm_playlist_handle _playlistHandle;
  CVDisplayLinkRef _displayLink;
}

@property (nonatomic, assign) NSSize lastSize;
@property (nonatomic, strong) NSDate *lastPresetChange;
@property (nonatomic, strong) NSTimer *cpuMonitorTimer;
@property (nonatomic, assign) NSUInteger highCPUFrames;
@property (nonatomic, assign) NSUInteger blackFrameCount;

@property (nonatomic, strong) ProjectMPresetBlacklist *presetsBlacklist;

@end

@implementation ProjectMView

#pragma mark - Initialization

- (instancetype)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format {
  self = [super initWithFrame:frameRect pixelFormat:format];
  if (self) {
    [self setWantsBestResolutionOpenGLSurface:YES];
    
    _presetsBlacklist = [[ProjectMPresetBlacklist alloc] init];
  }
  return self;
}

- (void)dealloc {
  [self cleanup];
}

#pragma mark - Lifecycle

- (void)renderFrame {
  if (!_pmHandle) return;

  CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
  CGLLockContext(cglContext);

  [[self openGLContext] makeCurrentContext];

  projectm_opengl_render_frame(_pmHandle);
  
  /// Some presets are broken and render black screens.
  /// Better skip and blacklist them!
  [self checkForBlackScreen];

  [[self openGLContext] flushBuffer];

  CGLUnlockContext(cglContext);
}

- (void)prepareOpenGL {
  [super prepareOpenGL];
  [[self openGLContext] makeCurrentContext];

  GLint swapInt = 1;
  [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLContextParameterSwapInterval];

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  _pmHandle = [self setupHandle];
  if (!_pmHandle) {
    NSLog(@"projectm_create failed");
    return;
  }

  [self loadTextures];

  _playlistHandle = projectm_playlist_create(_pmHandle);
  if (!_playlistHandle) {
    return;
  }

  [self loadPresets];
  projectm_playlist_set_retry_count(_playlistHandle, 5);

  [self startDisplayLink];
  
  /// Some presets fail to load the textures for Sillicon Macs, spiking the CPU to >70% and rendering weird colors.
  /// It's a known limitation described here: https://blenderartists.org/t/m1-macs-unsupported-log-once-explanation/1470335
  /// To prevent this, I'm using a timer that will monitor the CPU and skip the current preset if its problematic.
  [self startCPUMonitorTimer];
}

- (void)reshape {
  [super reshape];

  NSRect bounds = [self bounds];
  NSRect backingBounds = [self convertRectToBacking:bounds];

  if (NSEqualSizes(backingBounds.size, _lastSize)) {
    return;
  }
  _lastSize = backingBounds.size;

  [[self openGLContext] makeCurrentContext];

  if (_pmHandle) {
    projectm_set_window_size(_pmHandle, (unsigned int)NSWidth(backingBounds), (unsigned int)NSHeight(backingBounds));
  }
  glViewport(0, 0, NSWidth(backingBounds), NSHeight(backingBounds));
}

- (void)viewDidMoveToWindow {
  [super viewDidMoveToWindow];

  if (self.window == nil) {
    [self cleanup];
  }
}

#pragma mark - DisplayLink

- (void)startDisplayLink {
  CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
  CVDisplayLinkSetOutputCallback(_displayLink, &displayLinkCallback, (__bridge void *)self);

  CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
  CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
  CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(_displayLink, cglContext, cglPixelFormat);

  CVDisplayLinkStart(_displayLink);
}

- (void)startCPUMonitorTimer {
  _cpuMonitorTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                      target:self
                                                    selector:@selector(checkCPUUsage:)
                                                    userInfo:nil
                                                     repeats:YES];
}

static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink,
                                    const CVTimeStamp *now,
                                    const CVTimeStamp *outputTime,
                                    CVOptionFlags flagsIn,
                                    CVOptionFlags *flagsOut,
                                    void *displayLinkContext) {
  ProjectMView *view = (__bridge ProjectMView *)displayLinkContext;
  [view renderFrame];
  return kCVReturnSuccess;
}

- (void)checkCPUUsage:(id)sender {
  if (_lastPresetChange && [[NSDate date] timeIntervalSinceDate:_lastPresetChange] < 3.0) {
    return;
  }
  
  thread_act_array_t threads;
  mach_msg_type_number_t threadCount;
  
  if (task_threads(mach_task_self(), &threads, &threadCount) != KERN_SUCCESS) {
    return;
  }
  
  double totalCPU = 0;
  for (int i = 0; i < threadCount; i++) {
    thread_basic_info_data_t threadInfo;
    mach_msg_type_number_t threadInfoCount = THREAD_BASIC_INFO_COUNT;
    
    if (thread_info(threads[i], THREAD_BASIC_INFO, (thread_info_t)&threadInfo, &threadInfoCount) == KERN_SUCCESS) {
      if (!(threadInfo.flags & TH_FLAGS_IDLE)) {
        totalCPU += threadInfo.cpu_usage / (double)TH_USAGE_SCALE * 100.0;
      }
    }
  }
  
  vm_deallocate(mach_task_self(), (vm_offset_t)threads, threadCount * sizeof(thread_t));
  
  if (totalCPU > kMaxCPUThreshold) {
    _highCPUFrames++;
    if (_highCPUFrames >= 2) {
      uint32_t currentIndex = [self currentPresetIndex];
      NSString *presetPath = [self presetPathForIndex:currentIndex];
      
      if (presetPath) {
        NSLog(@"High CPU detected (%.1f%%), skipping problematic preset: %@",
              totalCPU, presetPath ? presetPath : @"unknown" );
        
        projectm_playlist_remove_preset(_playlistHandle, currentIndex);

        [self.presetsBlacklist addToBlacklist:presetPath];
      }
      
      [self playNextPresetWithHardCut:YES];
    }
  } else {
    _highCPUFrames = 0;
  }
}

#pragma mark - Setup

- (projectm_handle)setupHandle {
  projectm_handle handle = projectm_create();
  if (!handle) {
    return nil;
  }
  projectm_set_mesh_size(handle, 32, 24);
  projectm_set_fps(handle, 30.0f);
  projectm_set_aspect_correction(handle, true);
  projectm_set_easter_egg(handle, 0);
  projectm_set_soft_cut_duration(handle, 3.0f);

  return handle;
}

- (void)loadTextures {
  NSString *texturesPath = [[NSBundle mainBundle] resourcePath];
  if (texturesPath) {
    projectm_set_texture_search_paths(_pmHandle, (const char *[]){[texturesPath UTF8String]}, 1);
  } else {
    NSLog(@"ProjectMView Erorr: ProjectMTextures folder missing from bundle!");
  }
}

- (void)loadPresets {
  NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
  if (!resourcePath) {
    return;
  }

  const char *cPath = [resourcePath fileSystemRepresentation];

  projectm_playlist_set_shuffle(_playlistHandle, true);

  uint32_t added = projectm_playlist_add_path(_playlistHandle, cPath, NO, NO);
  
  [self.presetsBlacklist filterPlaylist:_playlistHandle];
  
  if (projectm_playlist_size(_playlistHandle) > 0) {
    projectm_playlist_play_next(_playlistHandle, true);
  } else {
    NSString *fallback = [[NSBundle mainBundle] pathForResource:@"41" ofType:@"milk"];
    if (fallback) {
      projectm_load_preset_file(_pmHandle, [fallback UTF8String], false);
    }
  }
}

#pragma mark - Public

- (void)playNextPresetWithHardCut:(BOOL)hardCut {
  if (!_playlistHandle) return;
  
  CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
  CGLLockContext(cglContext);
  
  projectm_playlist_play_next(_playlistHandle, hardCut);
  _lastPresetChange = [NSDate date];
  _blackFrameCount = 0;
  
  CGLUnlockContext(cglContext);
}

- (void)playPreviousPresetWithHardCut:(BOOL)hardCut {
  if (!_playlistHandle) return;
  
  CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
  CGLLockContext(cglContext);
  
  projectm_playlist_play_previous(_playlistHandle, hardCut);
  _lastPresetChange = [NSDate date];
  _blackFrameCount = 0;
  
  CGLUnlockContext(cglContext);
}

- (void)playLastPresetWithHardCut:(BOOL)hardCut {
  if (!_playlistHandle) return;
  projectm_playlist_play_last(_playlistHandle, hardCut);
}

- (void)setShuffleEnabled:(BOOL)enabled {
  if (_playlistHandle) {
    projectm_playlist_set_shuffle(_playlistHandle, enabled);
  }
}

- (BOOL)isShuffleEnabled {
  return _playlistHandle ? projectm_playlist_get_shuffle(_playlistHandle) : NO;
}

- (void)addPCMData:(const float *)monoData length:(AVAudioFrameCount)length {
  if (!_pmHandle || !monoData || length == 0) return;
  projectm_pcm_add_float(_pmHandle, monoData, (unsigned int)length, PROJECTM_MONO);
}

#pragma mark - Deinit

- (void)cleanup {
  [_cpuMonitorTimer invalidate];
  _cpuMonitorTimer = nil;
  
  if (_displayLink) {
    CVDisplayLinkStop(_displayLink);
    CVDisplayLinkRelease(_displayLink);
    _displayLink = NULL;
  }
  if (_playlistHandle) {
    projectm_playlist_destroy(_playlistHandle);
    _playlistHandle = NULL;
  }
  if (_pmHandle) {
    projectm_destroy(_pmHandle);
    _pmHandle = NULL;
  }
}

#pragma mark - Black Screen Skipping

- (void)checkForBlackScreen {
  if (_lastPresetChange && [[NSDate date] timeIntervalSinceDate:_lastPresetChange] < kSecondsUntilPresetIsProblematic) {
    return;
  }
  
  GLint width = (GLint)_lastSize.width;
  GLint height = (GLint)_lastSize.height;
  
  if (width == 0 || height == 0) {
    return;
  }
  
  GLint sampleWidth = 100;
  GLint sampleHeight = 100;
  GLint x = (width - sampleWidth) / 2;
  GLint y = (height - sampleHeight) / 2;
  
  GLubyte *pixels = (GLubyte *)malloc(sampleWidth * sampleHeight * 4);
  if (!pixels) return;
  
  glReadPixels(x, y, sampleWidth, sampleHeight, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
  
  NSUInteger blackPixels = 0;
  NSUInteger totalPixels = sampleWidth * sampleHeight;
  NSUInteger threshold = 10;
  
  for (NSUInteger i = 0; i < totalPixels * 4; i += 4) {
    GLubyte r = pixels[i];
    GLubyte g = pixels[i + 1];
    GLubyte b = pixels[i + 2];
    
    if (r < threshold && g < threshold && b < threshold) {
      blackPixels++;
    }
  }
  
  free(pixels);
  
  float blackPercentage = (float)blackPixels / (float)totalPixels;
  if (blackPercentage > kBlackScreenMaxPercentage) {
    _blackFrameCount++;
    
    if (_blackFrameCount > kMaxBlackFramesBeforeSkip) {
      uint32_t currentIndex = [self currentPresetIndex];
      NSString *presetPath = [self presetPathForIndex:currentIndex];
      
      NSLog(@"Black screen detected (%.1f%% black), removing preset: %@",
                blackPercentage * 100, presetPath ? presetPath : @"unknown");
      
      projectm_playlist_remove_preset(_playlistHandle, currentIndex);
      
      if (presetPath) {
        [self.presetsBlacklist addToBlacklist:presetPath];
      }
      
      projectm_playlist_play_next(_playlistHandle, YES);
      _lastPresetChange = [NSDate date];
      _blackFrameCount = 0;
    }
  } else {
    _blackFrameCount = 0;
  }
}

#pragma mark - Private Helpers

- (uint32_t)currentPresetIndex {
  return projectm_playlist_get_position(_playlistHandle);
}

- (nullable NSString *)presetPathForIndex:(uint32_t)index {
  const char *presetPath = projectm_playlist_item(_playlistHandle, index);
  if (presetPath) {
    return [NSString stringWithUTF8String:presetPath];
  }
  return nil;
}

@end

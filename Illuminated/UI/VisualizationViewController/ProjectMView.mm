//
//  ProjectMView.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import <Cocoa/Cocoa.h>
#import "ProjectMView.h"
#import <projectM-4/playlist_items.h>
#import <projectM-4/playlist.h>
#import <projectM-4/playlist_playback.h>
#import <projectM-4/projectM.h>
#import <OpenGL/gl3.h>

@interface ProjectMView ()
{
  projectm_handle _pmHandle;
  projectm_playlist_handle _playlistHandle;
  NSTimer *_renderTimer;
}
@end

@implementation ProjectMView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format
{
  self = [super initWithFrame:frameRect pixelFormat:format];
  if (self) {
    [self setWantsBestResolutionOpenGLSurface:YES];
  }
  return self;
}

- (void)prepareOpenGL
{
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
  
  _renderTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0
                                                  target:self
                                                selector:@selector(renderFrame)
                                                userInfo:nil
                                                 repeats:YES];
}


- (void)reshape {
  [super reshape];
  NSRect bounds = [self bounds];
  [[self openGLContext] makeCurrentContext];
  
  if (_pmHandle) {
    projectm_set_window_size(_pmHandle,
                             (unsigned int)NSWidth(bounds),
                             (unsigned int)NSHeight(bounds));
  }
  glViewport(0, 0, NSWidth(bounds), NSHeight(bounds));
}

- (void)drawRect:(NSRect)dirtyRect {
  [self renderFrame];
}

- (void)renderFrame {
  if (!_pmHandle) return;
  
  [[self openGLContext] makeCurrentContext];
  
  projectm_opengl_render_frame(_pmHandle);
  
  [[self openGLContext] flushBuffer];
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
  NSString *texturesPath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"ProjectMTextures"];
  if (texturesPath) {
    projectm_set_texture_search_paths(_pmHandle, (const char*[]){[texturesPath UTF8String]}, 1);
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
  if (added > 0) {
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
  projectm_playlist_play_next(_playlistHandle, hardCut);
}

- (void)playPreviousPresetWithHardCut:(BOOL)hardCut {
  if (!_playlistHandle) return;
  projectm_playlist_play_previous(_playlistHandle, hardCut);
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
    if (_renderTimer) {
        [_renderTimer invalidate];
        _renderTimer = nil;
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

- (void)dealloc {
    [self cleanup];
}

- (void)viewDidMoveToWindow {
  [super viewDidMoveToWindow];
  
  if (self.window == nil) {
      [self cleanup];
  }
}


@end

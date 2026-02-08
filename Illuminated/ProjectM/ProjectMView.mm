//
//  ProjectMView.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import <Cocoa/Cocoa.h>
#import "ProjectMView.h"
#import <projectM-4/playlist_items.h>
#import <OpenGL/gl3.h>

@interface ProjectMHandler ()
{
    projectm_handle _pmHandle;
    projectm_playlist_handle _playlistHandle;
    NSTimer *_renderTimer;
  NSTimer *_presetChangeTimer;
  NSTimeInterval _presetDuration;
}
@end

@implementation ProjectMHandler

- (instancetype)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format
{
    self = [super initWithFrame:frameRect pixelFormat:format];
    if (self) {
        // Optional: want continuous redraws
        [self setWantsBestResolutionOpenGLSurface:YES];
    }
    return self;
}

- (void)prepareOpenGL
{
    [super prepareOpenGL];
    [[self openGLContext] makeCurrentContext];

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    _pmHandle = projectm_create();
    if (!_pmHandle) {
        NSLog(@"projectm_create failed");
        return;
    }

    projectm_set_mesh_size(_pmHandle, 96, 72);
    projectm_set_fps(_pmHandle, 45.0f);
    projectm_set_aspect_correction(_pmHandle, true);
    projectm_set_easter_egg(_pmHandle, 0);
    projectm_set_soft_cut_duration(_pmHandle, 3.0f);

    _playlistHandle = projectm_playlist_create(_pmHandle);
    if (!_playlistHandle) {
        NSLog(@"projectm_playlist_create failed");
        return;
    }
  
  _presetDuration = 10.0;
  
  NSString *bundlePath = [[NSBundle mainBundle] resourcePath];
  [self loadPresetsFromDirectory:bundlePath recurseSubdirs:NO allowDuplicates:NO];

    // Optional defaults
    projectm_playlist_set_shuffle(_playlistHandle, true);
    projectm_playlist_set_retry_count(_playlistHandle, 5);

  if (projectm_playlist_size(_playlistHandle) == 0) {
          NSString *fallback = [[NSBundle mainBundle] pathForResource:@"131" ofType:@"milk"];
          if (fallback) {
              projectm_load_preset_file(_pmHandle, [fallback UTF8String], false);
          }
      }

    _renderTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0
                                                    target:self
                                                  selector:@selector(renderFrame)
                                                  userInfo:nil
                                                   repeats:YES];
  
  _presetChangeTimer = [NSTimer scheduledTimerWithTimeInterval:_presetDuration
                                                        target:self
                                                      selector:@selector(autoAdvancePreset)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)autoAdvancePreset
{
    if (!_playlistHandle) return;

    // Optional: only advance if shuffle is on, or always
    [self playNextPresetWithHardCut:NO];  // smooth transition

    // Optional: reset timer if you want variable durations per preset
    // [_presetChangeTimer invalidate];
    // _presetChangeTimer = [NSTimer scheduledTimerWithTimeInterval:randomDuration ...];
}

- (void)loadPresetsFromDirectory:(NSString *)directoryPath
                   recurseSubdirs:(BOOL)recurse
                   allowDuplicates:(BOOL)allow
{
    if (!_playlistHandle || !directoryPath) return;

    const char *cPath = [directoryPath fileSystemRepresentation];
    uint32_t added = projectm_playlist_add_path(_playlistHandle, cPath, recurse, allow);

    NSLog(@"Added %u presets from %@", added, directoryPath);

    if (added > 0) {
        // Start with a random one (shuffle must be enabled for randomness)
        projectm_playlist_set_shuffle(_playlistHandle, true);
        projectm_playlist_play_next(_playlistHandle, false);  // false = smooth transition
    }
}

- (void)playRandomPresetWithHardCut:(BOOL)hardCut
{
    if (!_playlistHandle) return;

    // In this API version: random = shuffle + play_next
    BOOL wasShuffle = projectm_playlist_get_shuffle(_playlistHandle);
    projectm_playlist_set_shuffle(_playlistHandle, true);
    projectm_playlist_play_next(_playlistHandle, hardCut);
    projectm_playlist_set_shuffle(_playlistHandle, wasShuffle);
}

- (void)playNextPresetWithHardCut:(BOOL)hardCut
{
    if (!_playlistHandle) return;
    projectm_playlist_play_next(_playlistHandle, hardCut);
}

- (void)playPreviousPresetWithHardCut:(BOOL)hardCut
{
    if (!_playlistHandle) return;
    projectm_playlist_play_previous(_playlistHandle, hardCut);
}

- (void)playLastPresetWithHardCut:(BOOL)hardCut
{
    if (!_playlistHandle) return;
    projectm_playlist_play_last(_playlistHandle, hardCut);
}

- (void)setShuffleEnabled:(BOOL)enabled
{
    if (_playlistHandle) {
        projectm_playlist_set_shuffle(_playlistHandle, enabled);
    }
}

- (BOOL)isShuffleEnabled
{
    return _playlistHandle ? projectm_playlist_get_shuffle(_playlistHandle) : NO;
}

- (void)setRetryCount:(uint32_t)count
{
    if (_playlistHandle) {
        projectm_playlist_set_retry_count(_playlistHandle, count);
    }
}

- (uint32_t)retryCount
{
    return _playlistHandle ? projectm_playlist_get_retry_count(_playlistHandle) : 0;
}

- (void)addPCMData:(const float *)monoData length:(AVAudioFrameCount)length
{
    if (!_pmHandle || !monoData || length == 0) return;
    projectm_pcm_add_float(_pmHandle, monoData, (unsigned int)length, PROJECTM_MONO);
}

- (void)reshape
{
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

- (void)drawRect:(NSRect)dirtyRect
{
    [self renderFrame];
}

- (void)renderFrame
{
    if (!_pmHandle) return;

    [[self openGLContext] makeCurrentContext];

    // Optional: projectm_set_time(_pmHandle, CACurrentMediaTime()); // if time-based effects need explicit time
    projectm_opengl_render_frame(_pmHandle);

    [[self openGLContext] flushBuffer];
}

- (void)dealloc
{
    if (_renderTimer) {
        [_renderTimer invalidate];
    }
    if (_playlistHandle) {
        projectm_playlist_destroy(_playlistHandle);
    }
    if (_pmHandle) {
        projectm_destroy(_pmHandle);
    }
}

@end

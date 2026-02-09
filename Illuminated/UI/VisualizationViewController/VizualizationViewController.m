//
//  VizualizationViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import "VizualizationViewController.h"
#import "PlaybackManager.h"
#import "ProjectMView.h"
#import "VisualizationPreset.h"
#import "VizualizationView.h"

@interface VizualizationViewController ()

@property(strong) IBOutlet VizualizationView *vizualizationView;

@property(nonatomic, strong) ProjectMView *projectMView;

@end

@implementation VizualizationViewController

- (void)loadView {
  NSOpenGLPixelFormatAttribute attrs[] = {NSOpenGLPFAOpenGLProfile,
                                          NSOpenGLProfileVersion3_2Core, // or Legacy if needed
                                          NSOpenGLPFADoubleBuffer,
                                          NSOpenGLPFAColorSize,
                                          24,
                                          NSOpenGLPFAAlphaSize,
                                          8,
                                          NSOpenGLPFADepthSize,
                                          24,
                                          NSOpenGLPFAAccelerated,
                                          0};

  NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
  if (!pixelFormat) {
    NSLog(@"Failed to create OpenGL pixel format");
    // fallback or error handling
  }

  NSRect initialFrame = NSMakeRect(0, 0, 800, 600); // will be resized by constraints
  self.projectMView = [[ProjectMView alloc] initWithFrame:initialFrame pixelFormat:pixelFormat];

  NSString *bundle = [[NSBundle mainBundle] resourcePath];

  if (!bundle) {
    NSLog(@"Presets folder not found in bundle");
    return;
  }

  self.view = self.projectMView;
  self.view.wantsLayer = YES;
}

#pragma mark - Lifecycle

- (void)viewDidAppear {
  [super viewDidAppear];

  [self registerForAudioBufferChanges];
}

- (void)viewDidDisappear {
  [super viewDidDisappear];
  

  [[PlaybackManager sharedManager] unregisterAudioBufferCallback];
  [self.vizualizationView stopRendering];
}

- (void)dealloc {
  NSLog(@"🔴 VizualizationViewController is being deallocated");
  [[PlaybackManager sharedManager] unregisterAudioBufferCallback];
  
  if (self.projectMView) {
    [self.projectMView cleanup];
  }
}

#pragma mark - Audio Buffer Registration

- (void)registerForAudioBufferChanges {
  __weak typeof(self) weakSelf = self;

  [[PlaybackManager sharedManager]
      registerAudioBufferCallback:^(const float *_Nonnull monoData, AVAudioFrameCount length) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (!strongSelf) return;
        [strongSelf.projectMView addPCMData:monoData length:length];
        //        [strongSelf.vizualizationView updateAudioData:monoData length:length];
      }];

  [self.vizualizationView startRendering];
}

@end

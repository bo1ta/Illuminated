//
//  VizualizationViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import "VizualizationViewController.h"
#import "PlaybackManager.h"
#import "ProjectMView.h"

@interface VizualizationViewController ()

@property(nonatomic, strong) ProjectMView *projectMView;

@end

@implementation VizualizationViewController

#pragma mark - Lifecycle

- (void)loadView {
  self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
  self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  self.view.wantsLayer = YES;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  NSOpenGLPixelFormatAttribute attrs[] = {NSOpenGLPFAOpenGLProfile,
                                          NSOpenGLProfileVersion3_2Core,
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
    return;
  }

  self.projectMView = [[ProjectMView alloc] initWithFrame:NSZeroRect pixelFormat:pixelFormat];
  self.projectMView.translatesAutoresizingMaskIntoConstraints = NO;

  [self.view addSubview:self.projectMView];
  self.view.wantsLayer = YES;

  [NSLayoutConstraint activateConstraints:@[
    [self.projectMView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.projectMView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.projectMView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.projectMView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
  ]];
}

- (void)viewDidLayout {
  [super viewDidLayout];
}

- (void)viewDidAppear {
  [super viewDidAppear];

  [self registerForAudioBufferChanges];
}

- (void)viewDidDisappear {
  [super viewDidDisappear];

  [[PlaybackManager sharedManager] unregisterAudioBufferCallback];
}

- (void)dealloc {
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
      }];
}

@end

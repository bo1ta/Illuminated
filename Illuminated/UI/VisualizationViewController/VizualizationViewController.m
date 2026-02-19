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

@property(nonatomic, strong) NSButton *previousPresetButton;
@property(nonatomic, strong) NSButton *nextPresetButton;
@property(nonatomic, strong) NSButton *fullScreenButton;

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

  [self setupProjectMView];
  if (!self.projectMView) {
    return;
  }

  [self setupPresetControlButtons];
  [self setupFullScreenButton];
}

- (void)viewDidAppear {
  [super viewDidAppear];

  [self registerForAudioBufferChanges];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(windowDidEnterFullScreen:)
                                               name:NSWindowDidEnterFullScreenNotification
                                             object:self.view.window];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(windowDidExitFullScreen:)
                                               name:NSWindowDidExitFullScreenNotification
                                             object:self.view.window];
}

- (void)viewDidDisappear {
  [super viewDidDisappear];

  [[PlaybackManager sharedManager] unregisterAudioBufferCallback];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];

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

        if (strongSelf) {
          [strongSelf.projectMView addPCMData:monoData length:length];
        }
      }];
}

#pragma mark - View Setup

- (void)setupProjectMView {
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

  [NSLayoutConstraint activateConstraints:@[
    [self.projectMView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.projectMView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.projectMView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.projectMView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
}

- (void)setupPresetControlButtons {
  self.previousPresetButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"chevron.left"
                                                                  accessibilityDescription:@"Previous"]
                                                 target:self
                                                 action:@selector(previousPresetAction:)];
  self.nextPresetButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"chevron.right"
                                                              accessibilityDescription:@"Next"]
                                             target:self
                                             action:@selector(nextPresetAction:)];

  for (NSButton *button in @[ self.previousPresetButton, self.nextPresetButton ]) {
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.bezelStyle = NSBezelStyleRegularSquare;
    button.controlSize = NSControlSizeRegular;
    button.wantsLayer = YES;
    button.layer.backgroundColor = [NSColor colorWithWhite:0.2 alpha:0.7].CGColor;
    button.layer.cornerRadius = 4;
    button.contentTintColor = NSColor.whiteColor;
    [self.view addSubview:button];
  }

  [NSLayoutConstraint activateConstraints:@[
    [self.previousPresetButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
    [self.previousPresetButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-20],
    [self.previousPresetButton.widthAnchor constraintEqualToConstant:25],
    [self.previousPresetButton.heightAnchor constraintEqualToConstant:25],

    [self.nextPresetButton.leadingAnchor constraintEqualToAnchor:self.previousPresetButton.trailingAnchor constant:8],
    [self.nextPresetButton.bottomAnchor constraintEqualToAnchor:self.previousPresetButton.bottomAnchor],
    [self.nextPresetButton.widthAnchor constraintEqualToConstant:25],
    [self.nextPresetButton.heightAnchor constraintEqualToConstant:25]
  ]];
}

- (void)setupFullScreenButton {
  self.fullScreenButton =
      [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"arrow.up.left.and.arrow.down.right"
                                          accessibilityDescription:@"Enter Fullscreen"]
                         target:self
                         action:@selector(toggleFullScreen:)];

  self.fullScreenButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.fullScreenButton.bezelStyle = NSBezelStyleRegularSquare;
  self.fullScreenButton.controlSize = NSControlSizeRegular;
  self.fullScreenButton.wantsLayer = YES;
  self.fullScreenButton.layer.backgroundColor = [NSColor colorWithWhite:0.2 alpha:0.7].CGColor;
  self.fullScreenButton.layer.cornerRadius = 4;
  self.fullScreenButton.contentTintColor = NSColor.whiteColor;
  self.fullScreenButton.toolTip = @"Toggle Fullscreen";

  [self.view addSubview:self.fullScreenButton];

  [NSLayoutConstraint activateConstraints:@[
    [self.fullScreenButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
    [self.fullScreenButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-20],
    [self.fullScreenButton.widthAnchor constraintEqualToConstant:25],
    [self.fullScreenButton.heightAnchor constraintEqualToConstant:25]
  ]];
}

#pragma mark - Button Actions

- (void)toggleFullScreen:(id)sender {
  [self.projectMView.window toggleFullScreen:sender];

  [self updateFullScreenButtonForCurrentState];
}

- (void)previousPresetAction:(id)sender {
  [self.projectMView playPreviousPresetWithHardCut:YES];
}

- (void)nextPresetAction:(id)sender {
  [self.projectMView playNextPresetWithHardCut:YES];
}

#pragma mark - Notification actions

- (void)updateFullScreenButtonForCurrentState {
  BOOL isFullscreen = (self.view.window.styleMask & NSWindowStyleMaskFullScreen) != 0;
  NSString *symbolName = isFullscreen ? @"arrow.down.right.and.arrow.up.left" : @"arrow.up.left.and.arrow.down.right";
  self.fullScreenButton.image =
      [NSImage imageWithSystemSymbolName:symbolName
                accessibilityDescription:isFullscreen ? @"Exit Fullscreen" : @"Enter Fullscreen"];
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification {
  [self updateFullScreenButtonForCurrentState];

  self.fullScreenButton.layer.backgroundColor = [NSColor colorWithWhite:0.2 alpha:0.9].CGColor;
}

- (void)windowDidExitFullScreen:(NSNotification *)notification {
  [self updateFullScreenButtonForCurrentState];

  // Restore normal appearance
  self.fullScreenButton.layer.backgroundColor = [NSColor colorWithWhite:0.2 alpha:0.7].CGColor;
}

@end

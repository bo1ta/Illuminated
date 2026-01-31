//
//  VizualizationView.m
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import "VizualizationView.h"
#import "AudioProcessor.h"
#import "MetalRenderer.h"
#import "VisualizationPreset.h"
#import "VisualizationPresetQueue.h"

@interface VizualizationView ()

@property (nonatomic, strong) MTKView *metalView;
@property (nonatomic, strong, nullable) MetalRenderer *renderer;
@property (nonatomic, strong) VisualizationPresetQueue *presetQueue;

@property (nonatomic, strong, nullable) NSButton *previousButton;
@property (nonatomic, strong, nullable) NSButton *nextButton;

@end

@implementation VizualizationView {
  MTKView *_metalView;
  MetalRenderer *_renderer;
  VisualizationPresetQueue *_presetQueue;
}

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (void)commonInit {
  // Create Metal view
  _metalView = [[MTKView alloc] initWithFrame:self.bounds];
  _metalView.device = MTLCreateSystemDefaultDevice();
  _metalView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  _metalView.paused = YES; // We'll control rendering manually
  _metalView.enableSetNeedsDisplay = NO;

  if (!_metalView.device) {
    NSLog(@"VizualizationView: Metal is not supported on this device");
    return;
  }

  [self addSubview:_metalView];

  [self setupControlButtons];

  // Create renderer
  _renderer = [[MetalRenderer alloc] initWithMetalKitView:_metalView audioBufferSize:1024];

  if (!_renderer) {
    NSLog(@"VizualizationView: Failed to create renderer");
    return;
  }

  _metalView.delegate = _renderer;

  _presetQueue = [VisualizationPresetQueue queueWithAllAvailablePresets];

  NSLog(@"VizualizationView: Initialized with %lu presets", (unsigned long)_presetQueue.count);
}

- (void)setupControlButtons {
  // Previous button
  NSButton *previousButton = [NSButton buttonWithTitle:@"◀" target:self action:@selector(previousPreset)];
  previousButton.frame = CGRectMake(20, 20, 44, 44);
  previousButton.bordered = NO; // For a cleaner look
  previousButton.bezelStyle = NSBezelStyleRoundRect;
  [self addSubview:previousButton];
  _previousButton = previousButton;

  // Next button
  NSButton *nextButton = [NSButton buttonWithTitle:@"▶" target:self action:@selector(nextPreset)];
  nextButton.frame = CGRectMake(74, 20, 44, 44);
  nextButton.bordered = NO;
  nextButton.bezelStyle = NSBezelStyleRoundRect;
  [self addSubview:nextButton];
  _nextButton = nextButton;
}

- (void)previousButtonPressed {
  [self previousPreset];
}

- (void)nextButtonPressed {
  [self nextPreset];
}

#pragma mark - Properties

- (id<VisualizationPreset>)currentPreset {
  return _renderer.currentPreset;
}

#pragma mark - Audio Updates

- (void)updateAudioData:(const float *)data length:(NSUInteger)length {
  if (_renderer && _renderer.audioProcessor) {
    [_renderer.audioProcessor updateWithAudioData:data length:length];
  }
}

#pragma mark - Rendering Control

- (void)startRendering {
  _metalView.paused = NO;
  NSLog(@"VizualizationView: Started rendering");
}

- (void)stopRendering {
  _metalView.paused = YES;
  NSLog(@"VizualizationView: Stopped rendering");
}

#pragma mark - Preset Management

- (nullable id<VisualizationPreset>)nextPreset {
  id<VisualizationPreset> preset = [_presetQueue nextPreset];

  if (preset) {
    [_renderer switchToPreset:preset];
  }

  return preset;
}

- (nullable id<VisualizationPreset>)previousPreset {
  id<VisualizationPreset> preset = [_presetQueue previousPreset];

  if (preset) {
    [_renderer switchToPreset:preset];
  }

  return preset;
}

- (BOOL)switchToPreset:(id<VisualizationPreset>)preset {
  if (!preset) {
    return NO;
  }

  // Update the queue's current index to match
  [_presetQueue selectPresetWithIdentifier:preset.identifier];

  // Switch in the renderer
  return [_renderer switchToPreset:preset];
}

@end

//
//  MetalRenderer.m
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import "MetalRenderer.h"
#import "AudioProcessor.h"
#import "CircularWavePreset.h"
#import "ShaderTypes.h"
#import "AlienCorePreset.h"
#import "VisualizationPreset.h"

#pragma mark - Constants

static const NSUInteger kDefaultAudioBufferSize = 1024;
static const float kAmplitudeBoost = 5.0f;

#pragma mark - Private Interface

@interface MetalRenderer ()

@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property(nonatomic, strong) id<MTLBuffer> audioBuffer;
@property(nonatomic, strong) id<MTLBuffer> uniformBuffer;
@property(nonatomic, strong) AudioProcessor *audioProcessor;
@property(nonatomic, weak) MTKView *mtkView;

@property(nonatomic, assign) CFTimeInterval startTime;

@end

#pragma mark - Implementation

@implementation MetalRenderer

- (instancetype)init {
  NSAssert(NO, @"Use initWithMetalKitView: or initWithMetalKitView:audioBufferSize: instead");
  return nil;
}

- (nullable instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView {
  return [self initWithMetalKitView:mtkView audioBufferSize:kDefaultAudioBufferSize];
}

- (nullable instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView audioBufferSize:(NSUInteger)bufferSize {
  self = [super init];
  if (self) {
    _device = mtkView.device;
    if (!_device) {
      NSLog(@"MetalRenderer: No Metal device available");
      return nil;
    }

    _mtkView = mtkView;

    _commandQueue = [_device newCommandQueue];
    if (!_commandQueue) {
      NSLog(@"MetalRenderer: Failed to create command queue");
      return nil;
    }

    _audioProcessor = [[AudioProcessor alloc] initWithBufferSize:bufferSize];
    if (!_audioProcessor) {
      NSLog(@"MetalRenderer: Failed to create audio processor");
      return nil;
    }

    _startTime = CACurrentMediaTime();

    if (![self createMetalBuffersWithSize:bufferSize]) {
      return nil;
    }

    // Set default preset
    _currentPreset = [[AlienCorePreset alloc] init];

    if (![self buildPipelineStateForPreset:_currentPreset]) {
      return nil;
    }
  }
  return self;
}

#pragma mark - Properties

- (AudioProcessor *)audioProcessor {
  return _audioProcessor;
}

- (void)setCurrentPreset:(id<VisualizationPreset>)currentPreset {
  if (currentPreset) {
    [self switchToPreset:currentPreset];
  }
}

#pragma mark - Preset Management

- (BOOL)switchToPreset:(id<VisualizationPreset>)preset {
  if (!preset) {
    NSLog(@"MetalRenderer: Cannot switch to nil preset");
    return NO;
  }

  if (![self buildPipelineStateForPreset:preset]) {
    NSLog(@"MetalRenderer: Failed to build pipeline for preset '%@'", preset.displayName);
    return NO;
  }

  _currentPreset = preset;
  NSLog(@"MetalRenderer: Switched to preset '%@'", preset.displayName);
  return YES;
}

#pragma mark - Setup

- (BOOL)createMetalBuffersWithSize:(NSUInteger)bufferSize {
  _audioBuffer = [_device newBufferWithLength:(bufferSize * sizeof(float)) options:MTLResourceStorageModeShared];
  if (!_audioBuffer) {
    NSLog(@"MetalRenderer: Failed to create audio buffer");
    return NO;
  }

  _uniformBuffer = [_device newBufferWithLength:sizeof(Uniforms) options:MTLResourceStorageModeShared];
  if (!_uniformBuffer) {
    NSLog(@"MetalRenderer: Failed to create uniform buffer");
    return NO;
  }

  return YES;
}

- (BOOL)buildPipelineStateForPreset:(id<VisualizationPreset>)preset {
  id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
  if (!defaultLibrary) {
    NSLog(@"MetalRenderer: Failed to load default library");
    return NO;
  }

  id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:preset.vertexFunctionName];
  id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:preset.fragmentFunctionName];

  if (!vertexFunction || !fragmentFunction) {
    NSLog(@"MetalRenderer: Failed to load shader functions '%@' and '%@'",
          preset.vertexFunctionName,
          preset.fragmentFunctionName);
    return NO;
  }

  MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  pipelineDescriptor.label = [NSString stringWithFormat:@"%@Pipeline", preset.displayName];
  pipelineDescriptor.vertexFunction = vertexFunction;
  pipelineDescriptor.fragmentFunction = fragmentFunction;
  pipelineDescriptor.colorAttachments[0].pixelFormat = _mtkView.colorPixelFormat;

  if (_mtkView.depthStencilPixelFormat != MTLPixelFormatInvalid) {
    pipelineDescriptor.depthAttachmentPixelFormat = _mtkView.depthStencilPixelFormat;
  }

  // Configure blending based on preset
  if (preset.requiresBlending) {
    if ([preset respondsToSelector:@selector(configureBlending:)]) {
      [preset configureBlending:pipelineDescriptor.colorAttachments[0]];
    } else {
      // Default additive blending
      [self configureDefaultBlendingForAttachment:pipelineDescriptor.colorAttachments[0]];
    }
  }

  NSError *error = nil;
  _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
  if (!_pipelineState) {
    NSLog(@"MetalRenderer: Failed to create pipeline state: %@", error);
    return NO;
  }

  return YES;
}

- (void)configureDefaultBlendingForAttachment:(MTLRenderPipelineColorAttachmentDescriptor *)attachment {
  attachment.blendingEnabled = YES;
  attachment.rgbBlendOperation = MTLBlendOperationAdd;
  attachment.alphaBlendOperation = MTLBlendOperationAdd;
  attachment.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
  attachment.destinationRGBBlendFactor = MTLBlendFactorOne;
  attachment.sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
  attachment.destinationAlphaBlendFactor = MTLBlendFactorOne;
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(nonnull MTKView *)view {
  if (!_currentPreset) {
    return;
  }

  CFTimeInterval currentTime = CACurrentMediaTime();
  float time = (float)(currentTime - _startTime);

  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  commandBuffer.label = @"VisualizerCommand";

  MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
  if (!renderPassDescriptor) {
    return;
  }

  renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);

  id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
  renderEncoder.label = @"VisualizerEncoder";
  [renderEncoder setRenderPipelineState:_pipelineState];

  [self updateAudioBuffer];

  float amplitude = [self updateUniforms:time screenSize:view.drawableSize];

  // Allow preset to do custom setup
  if ([_currentPreset respondsToSelector:@selector(prepareForDrawingWithEncoder:time:amplitude:)]) {
    [_currentPreset prepareForDrawingWithEncoder:renderEncoder time:time amplitude:amplitude];
  }

  NSUInteger sampleCount = _audioProcessor.sampleCount;
  [renderEncoder setVertexBytes:&sampleCount length:sizeof(NSUInteger) atIndex:0];
  [renderEncoder setVertexBuffer:_audioBuffer offset:0 atIndex:1];
  [renderEncoder setVertexBuffer:_uniformBuffer offset:0 atIndex:2];
  
  [renderEncoder setFragmentBytes:&sampleCount length:sizeof(NSUInteger) atIndex:0];
  [renderEncoder setFragmentBuffer:_audioBuffer offset:0 atIndex:1];
  [renderEncoder setFragmentBuffer:_uniformBuffer offset:0 atIndex:2];

  // Calculate vertex count (preset can override)
  NSUInteger vertexCount = sampleCount;
  if ([_currentPreset respondsToSelector:@selector(vertexCountForAudioBufferSize:)]) {
    vertexCount = [_currentPreset vertexCountForAudioBufferSize:sampleCount];
  }

  // Draw using preset's primitive type
  [renderEncoder drawPrimitives:_currentPreset.primitiveType vertexStart:0 vertexCount:vertexCount];

  [renderEncoder endEncoding];
  [commandBuffer presentDrawable:view.currentDrawable];
  [commandBuffer commit];
}

- (void)updateAudioBuffer {
  float *gpuBuffer = (float *)_audioBuffer.contents;
  [_audioProcessor copySamplesToBuffer:gpuBuffer length:NULL];
}

- (float)updateUniforms:(float)time screenSize:(CGSize)size {
  Uniforms *uniforms = (Uniforms *)_uniformBuffer.contents;
  uniforms->time = time;
  uniforms->screenSize = (vector_float2){(float)size.width, (float)size.height};

  float amplitude = _audioProcessor.amplitude * kAmplitudeBoost;
  uniforms->amplitude = amplitude;

  return amplitude;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
  // Screen size is handled via uniforms in draw call
}

@end

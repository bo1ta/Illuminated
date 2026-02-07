//
//  VoidTunnelPreset.m
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import "NeuralPulsePreset.h"
#import <Foundation/Foundation.h>

@implementation NeuralPulsePreset

- (NSString *)identifier {
  return @"neural_pulse";
}

- (NSString *)displayName {
  return @"Neural Pulse";
}

- (NSString *)vertexFunctionName {
  return @"neuralPulseVertexShader";
}

- (NSString *)fragmentFunctionName {
  return @"neuralPulseFragmentShader";
}

- (MTLPrimitiveType)primitiveType {
  return MTLPrimitiveTypeTriangleStrip;
}

- (BOOL)requiresBlending {
  return YES;
}

- (NSUInteger)vertexCountForAudioBufferSize:(NSUInteger)bufferSize {
  return 4;
}

- (void)configureBlending:(MTLRenderPipelineColorAttachmentDescriptor *)attachment {
  attachment.blendingEnabled = YES;
  attachment.rgbBlendOperation = MTLBlendOperationAdd;
  attachment.alphaBlendOperation = MTLBlendOperationAdd;
  attachment.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
  attachment.destinationRGBBlendFactor = MTLBlendFactorOne;
  attachment.sourceAlphaBlendFactor = MTLBlendFactorOne;
  attachment.destinationAlphaBlendFactor = MTLBlendFactorOne;
}

@end

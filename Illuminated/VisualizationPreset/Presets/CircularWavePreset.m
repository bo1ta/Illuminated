//
//  CircularWavePreset.m
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import "CircularWavePreset.h"

@implementation CircularWavePreset

- (NSString *)identifier {
  return @"circular_wave";
}

- (NSString *)displayName {
  return @"Circular Wave";
}

- (NSString *)vertexFunctionName {
  return @"circularWaveVertexShader";
}

- (NSString *)fragmentFunctionName {
  return @"circularWaveFragmentShader";
}

- (MTLPrimitiveType)primitiveType {
  return MTLPrimitiveTypeTriangleStrip;
}

- (BOOL)requiresBlending {
  return YES;
}

- (void)configureBlending:(MTLRenderPipelineColorAttachmentDescriptor *)attachment {
  attachment.blendingEnabled = YES;
  attachment.rgbBlendOperation = MTLBlendOperationAdd;
  attachment.alphaBlendOperation = MTLBlendOperationAdd;
  attachment.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
  attachment.destinationRGBBlendFactor = MTLBlendFactorOne;
  attachment.sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
  attachment.destinationAlphaBlendFactor = MTLBlendFactorOne;
}

@end

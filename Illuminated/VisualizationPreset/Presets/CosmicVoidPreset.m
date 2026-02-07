//
//  CosmicVoidPreset.m
//  Illuminated
//
//  Created by Alexandru Solomon on 02.02.2026.
//

#import "CosmicVoidPreset.h"
#import <Foundation/Foundation.h>

@implementation CosmicVoidPreset

- (NSString *)identifier {
  return @"cosmic_void";
}

- (NSString *)displayName {
  return @"Cosmic Void";
}

- (NSString *)vertexFunctionName {
  return @"cosmicVoidVertexShader";
}

- (NSString *)fragmentFunctionName {
  return @"cosmicVoidFragmentShader";
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

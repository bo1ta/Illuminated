//
//  VoidTunnelPreset.m
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import <Foundation/Foundation.h>
#import "NeuralPulsePreset.h"

@implementation NeuralPulsePreset
- (NSString *)identifier {
  return @"neural_pulse";
}

- (NSString *)displayName {
  return @"Void Tunnel";
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
@end

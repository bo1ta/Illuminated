//
//  BarGraphPreset.m
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import "BarGraphPreset.h"

@implementation BarGraphPreset

- (NSString *)identifier {
  return @"bar_graph";
}

- (NSString *)displayName {
  return @"Bar Graph";
}

- (NSString *)vertexFunctionName {
  return @"barGraphVertexShader";
}

- (NSString *)fragmentFunctionName {
  return @"barGraphFragmentShader";
}

- (MTLPrimitiveType)primitiveType {
  return MTLPrimitiveTypeTriangleStrip;
}

- (BOOL)requiresBlending {
  return NO;
}

- (NSUInteger)vertexCountForAudioBufferSize:(NSUInteger)bufferSize {
  // Each bar needs 4 vertices (2 triangles) to form a quad
  // We'll simplify and use pairs
  return bufferSize * 2;
}

@end

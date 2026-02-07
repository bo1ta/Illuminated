//
//  SineVoronoiPreset.m
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import "SineVoronoiPreset.h"
#import <Foundation/Foundation.h>

@implementation SineVoronoiPreset

- (NSString *)identifier {
  return @"sine_voronoi";
}

- (NSString *)displayName {
  return @"Sine Voronoi";
}

- (NSString *)vertexFunctionName {
  return @"sineVoronoiVertexShader";
}

- (NSString *)fragmentFunctionName {
  return @"sineVoronoiFragmentShader";
}

- (MTLPrimitiveType)primitiveType {
  return MTLPrimitiveTypeTriangleStrip;
}

- (BOOL)requiresBlending {
  return NO;
}

- (NSUInteger)vertexCountForAudioBufferSize:(NSUInteger)bufferSize {
  return 4;
}

@end

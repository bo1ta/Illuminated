//
//  TriangleFractalPreset.m
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import <Foundation/Foundation.h>

#import "TriangleFractalPreset.h"

@implementation TriangleFractalPreset

- (NSString *)identifier {
    return @"triangle_fractal";
}

- (NSString *)displayName {
    return @"Triangle Fractal";
}

- (NSString *)vertexFunctionName {
    return @"triangleFractalVertexShader";
}

- (NSString *)fragmentFunctionName {
    return @"triangleFractalFragmentShader";
}

- (MTLPrimitiveType)primitiveType {
    return MTLPrimitiveTypeTriangleStrip;
}

- (BOOL)requiresBlending {
    return NO;
}

- (NSUInteger)vertexCountForAudioBufferSize:(NSUInteger)bufferSize {
    // Fullscreen quad: 4 vertices
    return 4;
}

@end

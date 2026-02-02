//
//  AlienCorePreset.m
//  Illuminated
//
//  Created by Alexandru Solomon on 01.02.2026.
//

#import <Foundation/Foundation.h>

#import "AlienCorePreset.h"

@implementation AlienCorePreset

- (NSString *)identifier {
    return @"alien_core";
}

- (NSString *)displayName {
    return @"Alien Core";
}

- (NSString *)vertexFunctionName {
    return @"alienCoreVertexShader";
}

- (NSString *)fragmentFunctionName {
    return @"alienCoreFragmentShader";
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

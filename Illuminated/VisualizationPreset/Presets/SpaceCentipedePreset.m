//
//  SpaceCentipedePreset.m
//  Illuminated
//
//  Created by Alexandru Solomon on 02.02.2026.
//

#import "SpaceCentipedePreset.h"

@implementation SpaceCentipedePreset

- (NSString *)identifier {
    return @"space_centipede";
}

- (NSString *)displayName {
    return @"Space Centipede";
}

- (NSString *)vertexFunctionName {
    return @"spaceCentipedeVertexShader";
}

- (NSString *)fragmentFunctionName {
    return @"spaceCentipedeFragmentShader";
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

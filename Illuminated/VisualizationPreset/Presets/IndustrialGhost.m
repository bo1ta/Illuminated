//
//  IndustrialGhost.m
//  Illuminated
//
//  Created by Alexandru Solomon on 07.02.2026.
//

#import "IndustrialGhost.h"
#import <Metal/Metal.h>

@implementation IndustrialGhost {
  NSArray<id<MTLTexture>> *_textures;
}

- (NSString *)identifier {
  return @"industrial_ghost";
}

- (NSString *)displayName {
  return @"Industrial Ghost";
}

- (NSString *)vertexFunctionName {
  return @"silentHillVertexShader";
}

- (NSString *)fragmentFunctionName {
  return @"silentHillFragmentShader";
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

#pragma mark - Texture Support

- (NSArray<NSString *> *)textureNames {
  return @[ @"industrial_wall" ];
}

- (void)texturesDidLoad:(NSArray<id<MTLTexture>> *)textures {
  _textures = textures;

  if (textures.count > 0) {
    NSLog(@"SilentHillPreset: Loaded %lu texture(s)", (unsigned long)textures.count);
  } else {
    NSLog(@"SilentHillPreset: No textures loaded, using procedural walls");
  }
}

@end

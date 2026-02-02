//
//  ShaderTypes.h
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name)                                                                                          \
  enum _name : _type _name;                                                                                            \
  enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

#pragma mark - Vertex Structures

typedef struct {
  vector_float2 position;
  vector_float4 color;
} Vertex;

#pragma mark - Uniform Structures

typedef struct {
  float time;
  vector_float2 screenSize;
  float amplitude;
} Uniforms;

#pragma mark - Visualization Modes

typedef NS_ENUM(NSInteger, VisualizationMode) {
  VisualizationModeCircularWave = 0,
  VisualizationModeBarGraph = 1,
  VisualizationModeWaveform = 2,
  VisualizationModeSpectrum = 3,
  VisualizationModeParticles = 4,
};

#endif /* ShaderTypes_h */

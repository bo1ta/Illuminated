//
//  FractalTriangle.metal
//  Illuminated
//
//  Created by Alexandru Solomon on 02.02.2026.
//

#include <metal_stdlib>
#include "ShaderTypes.h"
#include "Common.h"

using namespace metal;

vertex VertexOut triangleFractalVertexShader(uint vertexID [[vertex_id]],
                                             constant Uniforms &uniforms [[buffer(2)]])
{
    VertexOut out;
    
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };
    
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.color = float4(1.0, 1.0, 1.0, 1.0);
    
    return out;
}

fragment float4 triangleFractalFragmentShader(VertexOut in [[stage_in]],
                                              constant float *audioData [[buffer(1)]],
                                              constant Uniforms &uniforms [[buffer(2)]])
{
  // Normalize coordinates (-1 to 1)
  float2 position = in.position.xy;
  
  // Correct for aspect ratio
  position.x *= uniforms.screenSize.x / uniforms.screenSize.y;
  
  // Calculate average audio amplitude
  float avgAmplitude = 0.0;
  for (int i = 0; i < 16; i++) {
      avgAmplitude += abs(audioData[i * 64]);
  }
  avgAmplitude = avgAmplitude / 16.0 * uniforms.amplitude;
  
  // Add some audio modulation to time
  float modulatedTime = uniforms.time * (1.0 + avgAmplitude * 0.5);
  
  // Calculate distance field
  float dist = distfunc(position, modulatedTime, avgAmplitude);
  
  // Create black and white pattern
  float pattern = sin(dist * 16.0 + modulatedTime * 8.0) * 0.5 + 0.5;
  
  // Make pattern pulse with audio
  pattern *= 0.8 + avgAmplitude * 0.4;
  
  // Edge glow in white
  float edge = 0.02 / (abs(dist) + 0.01);
  float value = pattern + edge * avgAmplitude;
  
  // Clamp to 0-1
  value = clamp(value, 0.0, 1.0);
  
  // Return grayscale (R=G=B)
  return float4(value, value, value, 1.0);
}

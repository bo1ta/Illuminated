//
//  SineVoronoi.metal
//  Illuminated
//
//  Created by Alexandru Solomon on 02.02.2026.
//

#include <metal_stdlib>
#include "ShaderTypes.h"
#include "Common.h"

using namespace metal;

#define NUMBER_OF_POINTS 80

vertex VertexOut sineVoronoiVertexShader(uint vertexID [[vertex_id]],
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

fragment float4 sineVoronoiFragmentShader(VertexOut in [[stage_in]],
                                          constant float *audioData [[buffer(1)]],
                                          constant Uniforms &uniforms [[buffer(2)]])
{
  
  float2 fragCoord = (in.position.xy + 1.0) * 0.5 * uniforms.screenSize;
  
  float2 position = fragCoord / uniforms.screenSize;
  
  float4 color = float4(0.0, 0.0, 0.0, 1.0);
  
  float audioSum = 0.0;
  float audioMax = 0.0;
  
  for (int i = 0; i < 32; i++) {
      int idx = min(1023, i * 32);
      float sample = abs(audioData[idx]) * uniforms.amplitude;
      audioSum += sample;
      audioMax = max(audioMax, sample);
  }
  
  float audioLevel = audioSum / 32.0;
  float audioBeat = smoothstep(0.1, 0.3, audioMax);
  
  float time = uniforms.time * (1.0 + audioLevel * 0.5);
  
  float gridSize = 15.0 + sin(time * 0.5) * 5.0 * audioBeat;
  float2 gridPos = position * gridSize;
  float2 gridIndex = floor(gridPos);
  float2 gridFract = fract(gridPos);
  
  float minDist = 1.0;
  
  for (int y = -1; y <= 1; y++) {
      for (int x = -1; x <= 1; x++) {
          float2 neighbor = float2(float(x), float(y));
          
          float audioOffset = 0.0;
          if (x == 0 && y == 0) {
              int audioIdx = int(gridIndex.x + gridIndex.y) % 32;
              audioOffset = audioData[audioIdx * 32] * uniforms.amplitude * 0.3;
          }
          
          float2 point = 0.5 + 0.5 * sin(time * 0.7 +
                                        neighbor.x * 1.3 +
                                        neighbor.y * 2.1 +
                                        audioOffset);
          
          float2 diff = neighbor + point - gridFract;
          float dist = length(diff);
          
          minDist = min(minDist, dist);
      }
  }
  
  float cells = 1.0 - smoothstep(0.0, 0.1, minDist);
  
  cells *= (0.8 + 0.4 * sin(time * 3.0 + audioLevel * 10.0));
  
  float hue = position.x + position.y * 0.3 + time * 0.1 + audioLevel * 0.5;
  float3 rgbColor = hsv2rgb(fract(hue),
                            0.8 + audioBeat * 0.2,
                            cells * (0.7 + audioLevel * 0.3));
  
  color.rgb = rgbColor;
  
  float edges = 1.0 - smoothstep(0.08, 0.1, minDist);
  edges -= cells;
  color.rgb += float3(0.0, edges * audioBeat, edges * 0.5);
  
  return color;
}

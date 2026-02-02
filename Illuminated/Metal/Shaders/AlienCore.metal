//
//  AlienCore.metal
//  Illuminated
//
//  Created by Alexandru Solomon on 02.02.2026.
//

#include <metal_stdlib>
#include "ShaderTypes.h"
#include "Common.h"

using namespace metal;

vertex RaymarchVertexOut alienCoreVertexShader(uint vertexID [[vertex_id]])
{
  RaymarchVertexOut out;
  
  // Full screen quad
  float2 positions[4] = {
      float2(-1.0, -1.0),
      float2( 1.0, -1.0),
      float2(-1.0,  1.0),
      float2( 1.0,  1.0)
  };
  
  float2 uvs[4] = {
      float2(0.0, 0.0),
      float2(1.0, 0.0),
      float2(0.0, 1.0),
      float2(1.0, 1.0)
  };
  
  out.position = float4(positions[vertexID], 0.0, 1.0);
  out.uv = uvs[vertexID];
  out.color = float4(0.0, 0.0, 0.0, 1.0);
  
  return out;
}

fragment float4 alienCoreFragmentShader(RaymarchVertexOut in [[stage_in]],
                                         constant float *audioData [[buffer(1)]],
                                         constant Uniforms &uniforms [[buffer(2)]])
{
  // Convert UV to centered coordinates
  float2 uv = in.uv * 2.0 - 1.0;
  uv.x *= uniforms.screenSize.x / uniforms.screenSize.y;
  
  // Calculate audio amplitude from different frequency ranges
  float bassAmp = 0.0;
  float midAmp = 0.0;
  float highAmp = 0.0;
  
  for (int i = 0; i < 64; i++) {
      float sample = abs(audioData[i * 16]);
      if (i < 16) {
          bassAmp += sample;
      } else if (i < 40) {
          midAmp += sample;
      } else {
          highAmp += sample;
      }
  }
  
  bassAmp = (bassAmp / 16.0) * uniforms.amplitude;
  midAmp = (midAmp / 24.0) * uniforms.amplitude;
  highAmp = (highAmp / 24.0) * uniforms.amplitude;
  
  float avgAmplitude = (bassAmp + midAmp + highAmp) / 3.0;
  
  // Setup ray
  float3 ray = normalize(float3(uv.x, uv.y, 1.0));
  
  // Color accumulator
  float3 color = float3(0.0);
  
  // Raymarching parameters
  const int maxSteps = 64;
  float maxDist = 8.0;
  
  // Ray position starts behind camera
  float t = 0.0;
  
  for (int r = 0; r < maxSteps; r++) {
      // Current position along ray
      float3 p = float3(0.0, 0.0, -3.0) + ray * t;
      
      // Rotation (audio-reactive)
      p = rotateY(p, uniforms.time / 3.0 + bassAmp * 0.5);
      
      // Deformation based on distance and audio
      float mask = max(0.0, (1.0 - length(p / 3.0)));
      p = rotateY(p, mask * sin(uniforms.time / 2.0 + midAmp) * 1.2);
      p.y += sin(uniforms.time + p.x + bassAmp * 2.0) * mask * 0.5;
      p *= 1.1 + (sin(uniforms.time / 2.0) * mask * 0.3) + avgAmplitude * 0.2;
      
      // Get distance to scene
      float d = sceneMap(p, uniforms.time, avgAmplitude);
      
      // Hit detection
      if (d < 0.01 || r == maxSteps - 1) {
          // Calculate ambient occlusion (reduced intensity)
          float iter = float(r) / float(maxSteps);
          float ao = (1.0 - iter);
          ao *= ao * ao; // Cubic falloff instead of quadratic for darker AO
          ao = 1.0 - ao;
          
          // Mask for inner glow
          float glowMask = max(0.0, (1.0 - length(p / 2.0)));
          glowMask *= abs(sin(uniforms.time * -1.5 + length(p) + p.x + midAmp * 3.0) - 0.2);
          
          // Enhance noise contrast for darker areas
          float noiseVal = noisePattern(p, uniforms.time) * 4.0 - 2.8; // Increased threshold from 2.6 to 2.8
          noiseVal = max(0.0, noiseVal);
          noiseVal *= noiseVal; // Square it for more contrast
          
          // Core glow (cyan/teal) - audio reactive, more selective
          color += 1.0 * float3(0.1, 1.0, 0.8) * noiseVal * glowMask; // Reduced from 1.5 to 1.0
          color *= (1.0 + highAmp * 0.2); // Further reduced
          
          // Ambient light (blue/purple) - darker
          color += float3(0.08, 0.3, 0.5) * ao * 1.5; // Darker blue, reduced from 2.5 to 1.5
          
          // Depth fog (purple) - darker
          color += float3(0.2, 0.15, 0.35) * (t / 10.0); // Reduced from t/8.0
          
          // Overall brightness - darker
          color *= 0.8; // Reduced from 1.2 to 0.8
          
          // Darken the base more
          color = max(color - 0.15, float3(0.0)); // Subtract more
          
          break;
      }
      
      // March along ray (smaller steps for better quality)
      t += d * 0.5;
      
      // Early exit if too far
      if (t > maxDist) break;
  }
  
  // Vignetting effect - stronger for darker edges
  float2 vigUV = in.uv;
  vigUV *= 1.0 - vigUV.yx;
  float vig = vigUV.x * vigUV.y * 15.0; // Reduced from 20.0 for darker edges
  vig = pow(vig, 0.3); // Increased from 0.25 for more darkening
  color *= vig;
  
  // Color adjustment for better visual - more subtle
  color.g *= 0.85; // Slightly reduced green
  color.r *= 1.3;  // Reduced red boost from 1.5
  
  // Bass makes it pulse slightly red - more subtle
  color.r += bassAmp * 0.05; // Reduced from 0.1
  
  return float4(color, 1.0);
}

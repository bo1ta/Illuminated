//
//  InfiniteIFSBox.metal
//  Illuminated
//
//  Created by Alexandru Solomon on 02.02.2026.
//

#include <metal_stdlib>
using namespace metal;

#include <metal_stdlib>
#include "ShaderTypes.h"
#include "Common.h"

float hash21(float2 p) {
  p = fract(p * float2(234.34, 435.345));
  p += dot(p, p + 34.23);
  return fract(p.x * p.y);
}

// Smooth noise
inline float noise(float2 p) {
  float2 i = floor(p);
  float2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  
  float a = hash21(i);
  float b = hash21(i + float2(1.0, 0.0));
  float c = hash21(i + float2(0.0, 1.0));
  float d = hash21(i + float2(1.0, 1.0));
  
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion
inline float fbm(float2 p) {
  float value = 0.0;
  float amplitude = 0.5;
  
  for (int i = 0; i < 5; i++) {
    value += amplitude * noise(p);
    p *= 2.0;
    amplitude *= 0.5;
  }
  
  return value;
}

// Rotate point
float2 rotate(float2 p, float a) {
  float c = cos(a);
  float s = sin(a);
  return float2(p.x * c - p.y * s, p.x * s + p.y * c);
}

// ============================================================================
// MARK: - Cosmic Void Shaders
// ============================================================================

vertex RaymarchVertexOut cosmicVoidVertexShader(uint vertexID [[vertex_id]]) {
  RaymarchVertexOut out;
  
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
  out.color = float4(0.0);
  
  return out;
}

fragment float4 cosmicVoidFragmentShader(RaymarchVertexOut in [[stage_in]],
                                         constant float *audioData [[buffer(1)]],
                                         constant Uniforms &uniforms [[buffer(2)]]) {
  // Center and aspect correct UVs
  float2 uv = (in.uv - 0.5) * 2.0;
  uv.x *= uniforms.screenSize.x / uniforms.screenSize.y;
  
  // Audio analysis
  float bass = 0.0, mid = 0.0, high = 0.0;
  for (int i = 0; i < 32; i++) {
    float sample = abs(audioData[i * 32]);
    if (i < 8) bass += sample;
    else if (i < 20) mid += sample;
    else high += sample;
  }
  bass = (bass / 8.0) * uniforms.amplitude;
  mid = (mid / 12.0) * uniforms.amplitude;
  high = (high / 12.0) * uniforms.amplitude;
  
  float time = uniforms.time;
  
  // Distance from center
  float dist = length(uv);
  float angle = atan2(uv.y, uv.x);
  
  // === Swirling Vortex ===
  float spiral = dist * 8.0 - time * 2.0 + angle * 3.0;
  spiral += fbm(uv * 3.0 + time * 0.3) * 2.0;
  
  float spiralPattern = sin(spiral) * 0.5 + 0.5;
  spiralPattern *= (1.0 - smoothstep(0.0, 2.0, dist));
  
  // === Energy Streams ===
  float streams = 0.0;
  for (int i = 0; i < 6; i++) {
    float streamAngle = float(i) * 1.047 + time * 0.5; // 60 degrees apart
    
    // Rotate UV to align with stream
    float2 streamUV = rotate(uv, -streamAngle);
    
    // Stream shape
    float streamDist = abs(streamUV.y);
    float streamFlow = streamUV.x + time * 1.5 + mid * 2.0;
    
    // Use distance-based attenuation for stream width
    float stream = exp(-streamDist * 20.0);
    stream *= sin(streamFlow * 10.0) * 0.5 + 0.5;
    
    // Fade based on distance from center (radial falloff)
    float radialDist = length(streamUV);
    stream *= smoothstep(2.0, 0.0, radialDist);
    
    streams += stream;
  }
  
  // === Particles ===
  float particles = 0.0;
  for (int i = 0; i < 50; i++) {
    float seed = float(i) * 12.345;
    
    // Particle position (orbiting)
    float particleAngle = seed + time * (0.5 + bass * 0.5);
    float particleRadius = 0.3 + fract(seed * 0.123) * 1.2;
    particleRadius += sin(time * 2.0 + seed) * 0.1;
    
    float2 particlePos = float2(
                                cos(particleAngle) * particleRadius,
                                sin(particleAngle) * particleRadius
                                );
    
    // Particle brightness
    float particleDist = length(uv - particlePos);
    float particleSize = 0.015 + high * 0.02;
    
    particles += exp(-particleDist / particleSize) * 0.3;
  }
  
  // === Central Void ===
  float voidCore = 1.0 - smoothstep(0.05, 0.3, dist);
  voidCore += (1.0 - smoothstep(0.3, 0.35, dist)) * 0.5;
  
  // Pulsing void
  voidCore *= 0.8 + sin(time * 3.0 + bass * 5.0) * 0.2;
  
  // === Nebula Background ===
  float nebula = fbm(uv * 2.0 + time * 0.1);
  nebula += fbm(uv * 4.0 - time * 0.15) * 0.5;
  nebula = pow(nebula, 2.0);
  nebula *= 0.3;
  
  // === Combine All Layers ===
  float3 color = float3(0.0);
  
  // Nebula base (dark blue/purple)
  color += float3(0.1, 0.05, 0.2) * nebula;
  
  // Spiral vortex (cyan to purple gradient)
  float3 spiralColor = mix(
                           float3(0.2, 0.6, 1.0),  // Cyan
                           float3(0.8, 0.2, 0.6),  // Magenta
                           spiralPattern
                           );
  color += spiralColor * spiralPattern * (0.8 + mid * 0.5);
  
  // Energy streams (bright cyan)
  color += float3(0.3, 1.0, 0.9) * streams * (1.0 + mid * 0.8);
  
  // Particles (white/yellow)
  color += float3(1.0, 0.9, 0.6) * particles * (1.0 + high * 1.0);
  
  // Void core (deep purple with cyan edge)
  float3 voidColor = mix(
                         float3(0.05, 0.0, 0.1),  // Deep purple center
                         float3(0.2, 0.8, 1.0),   // Cyan edge
                         voidCore
                         );
  color += voidColor * voidCore * 2.0;
  
  // === Post Processing ===
  
  // Radial glow from center
  float glow = exp(-dist * 0.8) * 0.3;
  color += float3(0.2, 0.4, 0.6) * glow * (1.0 + bass * 0.5);
  
  // Vignette
  float vignette = 1.0 - dist * 0.4;
  vignette = clamp(vignette, 0.3, 1.0);
  color *= vignette;
  
  // Audio reactive brightness pulse
  color *= 0.9 + bass * 0.3 + mid * 0.2;
  
  // Contrast boost
  color = pow(color, float3(0.9));
  
  // Clamp
  color = clamp(color, 0.0, 1.5);
  
  return float4(color, 1.0);
}

//
//  IndustrialGhost.metal
//  Illuminated
//
//  Created by Alexandru Solomon on 07.02.2026.
//

#include <metal_stdlib>
#include "ShaderTypes.h"
#include "Common.h"

using namespace metal;

// Box SDF (for room)
inline float sdBox(float3 p, float3 b) {
    float3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// Sphere SDF (for ghosts)
float sdSphere(float3 p, float r) {
    return length(p) - r;
}

// Ghost shape
float ghost(float3 p, float3 pos, float t, float phase) {
    float3 localP = p - pos;
    
    // Floating motion
    localP.y -= sin(t * 2.0 + phase) * 0.3;
    
    // Body (sphere with distortion)
    float body = sdSphere(localP, 0.8);
    
    // Add wispy distortion
    float distortion = noise3D(localP * 3.0 + t * 0.5) * 0.2;
    body += distortion;
    
    // Trailing wisp
    float trail = sdSphere(localP + float3(0, -0.5, 0), 0.6);
    body = min(body, trail + 0.2);
    
    return body;
}

float2x2 rot(float a) {
    float c = cos(a);
    float s = sin(a);
    return float2x2(c, -s, s, c);
}

inline float hash21(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash21(i);
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Industrial room
float room(float3 p, float t) {
    // Main room - hollow box
    float outer = sdBox(p, float3(8.0, 4.0, 8.0));
    float inner = sdBox(p, float3(7.8, 3.8, 7.8));
    float walls = max(outer, -inner);
    
    // Add pipes along walls
    float pipes = 10.0;
    for (int i = 0; i < 4; i++) {
        float angle = float(i) * 1.571; // 90 degrees
        float3 pipeP = p;
        pipeP.xy = rot(angle) * pipeP.xy;
        float pipe = length(pipeP.xy - float2(7.5, 3.0)) - 0.1;
        pipes = min(pipes, pipe);
    }
    
    return min(walls, pipes);
}

// Scene SDF
float map(float3 p, float t, int hitType) {
    hitType = 0; // 0 = room, 1 = ghost
    
    float d = room(p, t);
    
    // Add 3 ghosts
    for (int i = 0; i < 3; i++) {
        float phase = float(i) * 2.094; // ~120 degrees
        float3 ghostPos = float3(
            sin(t * 0.3 + phase) * 4.0,
            0.0,
            cos(t * 0.3 + phase) * 4.0
        );
        
        float g = ghost(p, ghostPos, t, phase);
        if (g < d) {
            d = g;
            hitType = 1;
        }
    }
    
    return d;
}

// ============================================================================
// MARK: - Shaders
// ============================================================================

vertex RaymarchVertexOut silentHillVertexShader(uint vertexID [[vertex_id]]) {
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

fragment float4 silentHillFragmentShader(RaymarchVertexOut in [[stage_in]],
                                        constant float *audioData [[buffer(1)]],
                                        constant Uniforms &uniforms [[buffer(2)]],
                                        texture2d<float> wallTexture [[texture(0)]])
{
  // UV setup
  float2 uv = (in.uv - 0.5) * 2.0;
  uv.x *= uniforms.screenSize.x / uniforms.screenSize.y;
  
  float time = uniforms.time;
  
  // Audio analysis
  float bass = 0.0, mid = 0.0;
  for (int i = 0; i < 32; i++) {
      float sample = abs(audioData[i * 32]);
      if (i < 12) bass += sample;
      else mid += sample;
  }
  bass = (bass / 12.0) * uniforms.amplitude;
  mid = (mid / 20.0) * uniforms.amplitude;
  
  // === CAMERA ===
  float3 camPos = float3(
      sin(time * 0.15) * 5.0,
      1.5 + sin(time * 0.08) * 1.0,
      cos(time * 0.15) * 5.0
  );
  
  // Look towards center, but with some drift
  float3 target = float3(
      sin(time * 0.05) * 1.0,
      1.0 + cos(time * 0.03) * 0.5,
      cos(time * 0.05) * 1.0
  );
  float3 forward = normalize(target - camPos);
  float3 right = normalize(cross(float3(0.0, 1.0, 0.0), forward));
  float3 up = cross(forward, right);
  
  float3 rayDir = normalize(forward + right * uv.x + up * uv.y);
  
  // === RAYMARCHING ===
  float t = 0.0;
  float3 color = float3(0.0);
  const int maxSteps = 80;
  bool hit = false;
  int hitType = 0;
  
  for (int i = 0; i < maxSteps; i++) {
      float3 pos = camPos + rayDir * t;
      
      int currentHitType;
      float d = map(pos, time, currentHitType);
      
      if (d < 0.02) {
          hit = true;
          hitType = currentHitType;
          
          // Calculate normal
          float2 e = float2(0.01, 0.0);
          int dummy;
          float3 normal = normalize(float3(
              map(pos + e.xyy, time, dummy) - map(pos - e.xyy, time, dummy),
              map(pos + e.yxy, time, dummy) - map(pos - e.yxy, time, dummy),
              map(pos + e.yyx, time, dummy) - map(pos - e.yyx, time, dummy)
          ));
          
          if (hitType == 0) {
              // Room walls - use texture if available
              constexpr sampler texSampler(filter::linear, address::repeat);
              
              // Calculate texture coordinates based on position
              float2 texUV;
              if (abs(normal.y) > 0.5) {
                  // Floor/ceiling
                  texUV = pos.xz * 0.2;
              } else if (abs(normal.x) > 0.5) {
                  // Side walls
                  texUV = pos.yz * 0.2;
              } else {
                  // Front/back walls
                  texUV = pos.xy * 0.2;
              }
              
              float3 wallColor;
              if (wallTexture.get_width() > 0) {
                  // Sample texture
                  float4 texColor = wallTexture.sample(texSampler, texUV);
                  wallColor = texColor.rgb;
              } else {
                  // Fallback procedural texture - brighter
                  float concrete = noise(texUV * 10.0);
                  wallColor = float3(0.45, 0.42, 0.38) * (0.8 + concrete * 0.4);  // Lighter base color
              }
              
              // Lighting
              float3 lightPos = float3(0.0, 3.0, 0.0);
              float3 lightDir = normalize(lightPos - pos);
              float diffuse = max(dot(normal, lightDir), 0.0);
              
              // Brighter ambient + stronger diffuse
              color = wallColor * (0.35 + diffuse * 0.65);  // Was 0.15 + 0.3
              
              // Add rust stains
              float rust = noise(texUV * 5.0 + time * 0.01);
              rust = smoothstep(0.6, 0.8, rust);
              color += float3(0.15, 0.05, 0.0) * rust;
              
          } else {
              // Ghost - translucent, glowing
              float fresnel = pow(1.0 - abs(dot(normal, -rayDir)), 3.0);
              
              color = float3(0.6, 0.7, 0.8) * 0.5; // Pale blue-white
              color += float3(0.8, 0.9, 1.0) * fresnel * 0.8;
              
              // Pulsing with mid frequencies
              color *= (0.7 + mid * 0.6 + sin(time * 3.0) * 0.2);
          }
          
          break;
      }
      
      // Volumetric fog
      if (hitType == 1 || i > 30) {
          float fogDensity = 0.008 * (1.0 + bass * 0.3);
          color += float3(0.25, 0.22, 0.2) * fogDensity;
      }
      
      t += d * 0.7;
      if (t > 30.0) break;
  }
  
  // === FOG & ATMOSPHERE ===
  // Atmospheric fog (lighter than before)
  float fogAmount = 1.0 - exp(-t * 0.05);
  float3 fogColor = float3(0.4, 0.38, 0.35);
  color = mix(color, fogColor, fogAmount * 0.7);
  
  // === FILM GRAIN & NOISE ===
  float grain = hash21(in.uv * time) * 0.03;
  color += grain;
  
  // VHS-like noise lines
  float scanline = sin(in.uv.y * 200.0 + time * 5.0) * 0.015;
  color += scanline;
  
  // === COLOR GRADING ===
  // Desaturate
  float gray = dot(color, float3(0.299, 0.587, 0.114));
  color = mix(color, float3(gray), 0.25);
  
  // Sepia tone
  color.r *= 1.1;
  color.g *= 1.0;
  color.b *= 0.9;
  
  // Overall brightness
  color *= 1.1;
  color = pow(color, float3(0.9));
  
  // Vignette (less aggressive)
  float vignette = 1.0 - length(uv) * 0.4;
  vignette = clamp(vignette, 0.4, 1.0);
  color *= vignette;
  
  // Audio pulse
  color += bass * float3(0.05, 0.03, 0.02);
  
  return float4(color, 1.0);
}




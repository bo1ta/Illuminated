//
//  Common.metal
//  Illuminated
//
//  Created by Alexandru Solomon on 02.02.2026.
//

#include <metal_stdlib>
#include "Common.h"

using namespace metal;

float hash(uint n) {
    n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return float(n & 0x7fffffffU) / float(0x7fffffff);
}

float3 hsv2rgb(float h, float s, float v) {
    float3 k = float3(1.0, 2.0/3.0, 1.0/3.0);
    float3 p = abs(fract(float3(h, h, h) + k) * 6.0 - 3.0);
    return v * mix(float3(1.0), clamp(p - 1.0, 0.0, 1.0), s);
}

float triangleSDF(float2 p, float s) {
    return max(abs(p.x) * 0.866025 + p.y * 0.5, -p.y) - s * 0.5;
}

float lineSDF(float2 p, float2 v, float2 w) {
    float2 vw = w - v;
    float l2 = dot(vw, vw);
    float t = max(0.0, min(1.0, dot(p - v, vw) / l2));
    float2 projection = v + t * vw;
    return length(p - projection);
}

float distfunc(float2 p, float time, float amplitude) {
    p /= 0.1;
    float d = 1000.0;
    float n = 1.0;
    float2 s = float2(1.0, -1.0);
    
    float audioMod = amplitude * 2.0;
    
    float S = sin(time/3.14) * cos(time*0.125) * (1.0 + audioMod * 0.5);
    float C = cos(time/3.14) * sin(time*0.195) * (1.0 + audioMod * 0.3);
    
    for (int i = 0; i < 8; i++) {
        d = min(d, triangleSDF(p, 1.0));
        d = min(d, lineSDF(p, float2(-0.866, -0.5), float2(-0.866, -n*C)));
        d = min(d, lineSDF(p, float2(-0.866, -2.0), float2(0.866*2.0*n*S, -2.0)));
        n++;
        p += s * S;
        p.xy = float2(p.x * C - p.y * S, p.y * C + p.x * S) + s;
        s = -s;
    }
    return d;
}

float3 rotateY(float3 v, float t) {
    float cost = cos(t);
    float sint = sin(t);
    return float3(v.x * cost + v.z * sint, v.y, -v.x * sint + v.z * cost);
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// Simple 3D noise function (since we don't have texture sampling)
float hash(float3 p) {
    p = fract(p * float3(443.897, 441.423, 437.195));
    p += dot(p, p.yzx + 19.19);
    return fract((p.x + p.y) * p.z);
}

float noise3D(float3 p) {
  float3 i = floor(p);
  float3 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  
  float n = i.x + i.y * 157.0 + 113.0 * i.z;
  
  return mix(mix(mix(hash(float3(n + 0.0, 0, 0)), hash(float3(n + 1.0, 0, 0)), f.x),
                 mix(hash(float3(n + 157.0, 0, 0)), hash(float3(n + 158.0, 0, 0)), f.x), f.y),
             mix(mix(hash(float3(n + 113.0, 0, 0)), hash(float3(n + 114.0, 0, 0)), f.x),
                 mix(hash(float3(n + 270.0, 0, 0)), hash(float3(n + 271.0, 0, 0)), f.x), f.y), f.z);
}

float noisePattern(float3 p, float time) {
  float3 np = normalize(p);
  
  float a = noise3D(np * 3.0 + time * 0.05);
  float b = noise3D(np.yzx * 3.0 + time * 0.05 + 0.77);
  
  a = mix(a, 0.5, abs(np.x));
  b = mix(b, 0.5, abs(np.z));
  
  float noise = a + b - 0.4;
  noise = mix(noise, 0.5, abs(np.y) / 2.0);
  
  return noise;
}

float sceneMap(float3 p, float time, float audioAmplitude) {
  // Spheres with noise displacement
  float d = (-1.0 * length(p) + 3.0) + 1.5 * noisePattern(p, time);
  d = min(d, (length(p) - 1.5) + 1.5 * noisePattern(p, time));
  
  // Links (connecting structures)
  float m = 1.5 * (1.0 + audioAmplitude * 0.3); // Audio affects smoothness
  float s = 0.03;
  
  d = smin(d, max(abs(p.x) - s, abs(p.y + p.z * 0.2) - 0.07), m);
  d = smin(d, max(abs(p.z) - s, abs(p.x + p.y / 2.0) - 0.07), m);
  d = smin(d, max(abs(p.z - p.y * 0.4) - s, abs(p.x - p.y * 0.2) - 0.07), m);
  d = smin(d, max(abs(p.z * 0.2 - p.y) - s, abs(p.x + p.z) - 0.07), m);
  d = smin(d, max(abs(p.z * -0.2 + p.y) - s, abs(-p.x + p.z) - 0.07), m);
  
  return d;
}

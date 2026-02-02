//
//  Common.h
//  Illuminated
//
//  Created by Alexandru Solomon on 02.02.2026.
//

#ifndef Common_h
#define Common_h

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

struct RaymarchVertexOut {
    float4 position [[position]];
    float2 uv;
    float4 color;
};

float hash(uint n);
float hash(float3 p);
float noise3D(float3 p);
float3 hsv2rgb(float h, float s, float v);
float triangleSDF(float2 p, float s);
float lineSDF(float2 p, float2 v, float2 w);
float smin(float a, float b, float k);
float distfunc(float2 p, float time, float amplitude);
float3 rotateY(float3 v, float t);
float noisePattern(float3 p, float time);
float sceneMap(float3 p, float time, float audioAmplitude);


#endif /* Common_h */

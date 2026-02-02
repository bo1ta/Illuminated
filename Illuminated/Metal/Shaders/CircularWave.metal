//
//  CircularWave.metal
//  Illuminated
//
//  Created by Alexandru Solomon on 02.02.2026.
//

#include <metal_stdlib>
#include "ShaderTypes.h"
#include "Common.h"

using namespace metal;

vertex VertexOut circularWaveVertexShader(uint vertexID [[vertex_id]],
                                          constant float *audioData [[buffer(1)]],
                                          constant Uniforms &uniforms [[buffer(2)]])
{
    VertexOut out;
    
    // Map vertexID (0-1024) to 0.0-1.0
    float t = (float)vertexID / 1024.0;
    
    // Map to angle (Circular)
    float angle = t * 6.28318 + (uniforms.time * 0.2); // Slowly rotate
    
    // Get Audio PCM value (-1.0 to 1.0)
    float sample = audioData[vertexID];
    
    // Base radius + Audio modulation
    // sine wave distortion based on time
    float warp = sin(angle * 10.0 + uniforms.time * 2.0) * 0.05;
    float radius = 0.5 + (sample * 0.3 * uniforms.amplitude) + warp;
    
    // Calculate position
    float aspectRatio = uniforms.screenSize.x / uniforms.screenSize.y;
    float2 pos;
    pos.x = cos(angle) * radius;
    pos.y = sin(angle) * radius * aspectRatio; // Correct aspect ratio
    
    out.position = float4(pos, 0.0, 1.0);
    
    // Abstract Color Logic
    // HSL-like gradient based on angle and time
    float red = sin(angle + uniforms.time) * 0.5 + 0.5;
    float green = cos(angle * 2.0 - uniforms.time) * 0.5 + 0.5;
    float blue = sin(angle * 3.0 + uniforms.time) * 0.5 + 0.5;
    
    // Boost intensity by amplitude for "beat flash"
    float intensity = 1.0 + uniforms.amplitude * 2.0;
    
    out.color = float4(red * intensity, green * intensity, blue * intensity, 1.0);
    
    return out;
}

fragment float4 circularWaveFragmentShader(VertexOut in [[stage_in]],
                                           constant Uniforms &uniforms [[buffer(2)]])
{
    return in.color;
}

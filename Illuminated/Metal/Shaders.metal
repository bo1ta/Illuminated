//
//  Shaders.metal
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#include <metal_stdlib>
#include "ShaderTypes.h"

using namespace metal;

typedef struct {
    float4 position [[position]];
    float4 color;
} VertexOut;

float hash(uint n) {
    n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return float(n & 0x7fffffffU) / float(0x7fffffff);
}

// ============================================================================
// MARK: - Circular Wave Preset
// ============================================================================

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
    // Add some sine wave distortion based on time
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
    // Basic pass-through color with a slight glow calculation could go here
    // For now, vertex color is sufficient for the line strip
    return in.color;
}

// ============================================================================
// MARK: - Bar Graph Preset
// ============================================================================

vertex VertexOut barGraphVertexShader(uint vertexID [[vertex_id]],
                                      constant float *audioData [[buffer(1)]],
                                      constant Uniforms &uniforms [[buffer(2)]])
{
    VertexOut out;
    
    // Each bar is made of 2 vertices (triangle strip style)
    uint barIndex = vertexID / 2;
    bool isTop = (vertexID % 2) == 1;
    
    // Get audio sample
    float sample = abs(audioData[barIndex]);
    float height = sample * uniforms.amplitude * 0.5;
    
    // Calculate bar position (-1 to 1 across screen)
    float numBars = 1024.0 / 2.0; // 512 bars
    float barWidth = 2.0 / numBars;
    float x = -1.0 + (barIndex * barWidth);
    
    // Y position (bottom at -0.8, top varies with audio)
    float y = isTop ? (-0.8 + height) : -0.8;
    
    out.position = float4(x, y, 0.0, 1.0);
    
    // Color based on height
    float intensity = height * 2.0;
    out.color = float4(0.2 + intensity, 0.5 + intensity * 0.5, 1.0, 1.0);
    
    return out;
}

fragment float4 barGraphFragmentShader(VertexOut in [[stage_in]])
{
    return in.color;
}

//
//  BarGraph.metal
//  Illuminated
//
//  Created by Alexandru Solomon on 02.02.2026.
//

#include <metal_stdlib>
#include "ShaderTypes.h"
#include "Common.h"

using namespace metal;

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

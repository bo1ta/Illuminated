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
    // Fix UV calculation
    float2 uv = (in.position.xy / uniforms.screenSize) * 2.0 - 1.0;
    uv.x *= uniforms.screenSize.x / uniforms.screenSize.y;
    
    // Better audio analysis
    float bass = 0.0, mid = 0.0, high = 0.0;
    for (int i = 0; i < 32; i++) {
        int idx = min(1023, i * 32);
        float sample = abs(audioData[idx]) * uniforms.amplitude;
        if (i < 10) bass += sample;
        else if (i < 22) mid += sample;
        else high += sample;
    }
    bass /= 10.0;
    mid /= 12.0;
    high /= 10.0;
    
    float time = uniforms.time;
    
    // Dynamic grid that responds to bass
    float gridSize = 8.0 + bass * 5.0 + sin(time * 0.3) * 2.0;
    float2 gridPos = uv * gridSize;
    float2 gridIndex = floor(gridPos);
    float2 gridFract = fract(gridPos);
    
    float minDist = 10.0;
    float2 minPoint = float2(0.0);
    float minCellId = 0.0;
    
    // Check neighboring cells
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 neighbor = float2(float(x), float(y));
            float2 cellIndex = gridIndex + neighbor;
            
            // Unique cell ID for variation
            float cellId = cellIndex.x * 12.9898 + cellIndex.y * 78.233;
            cellId = fract(sin(cellId) * 43758.5453);
            
            // Audio modulation per cell
            int audioIdx = int(abs(cellIndex.x + cellIndex.y)) % 32;
            float cellAudio = abs(audioData[audioIdx * 32]) * uniforms.amplitude;
            
            // Animated point position with multiple sine waves
            float2 point = float2(
                0.5 + 0.4 * sin(time * 0.8 + cellId * 6.28 + mid * 3.0),
                0.5 + 0.4 * cos(time * 0.6 + cellId * 4.71 + cellAudio * 5.0)
            );
            
            // Add orbital motion
            float orbit = time * 0.5 + cellId * 3.14;
            point += float2(cos(orbit), sin(orbit)) * 0.15 * bass;
            
            float2 diff = neighbor + point - gridFract;
            float dist = length(diff);
            
            if (dist < minDist) {
                minDist = dist;
                minPoint = neighbor + point;
                minCellId = cellId;
            }
        }
    }
    
    // Cell interior (filled areas)
    float cells = 1.0 - smoothstep(0.0, 0.15, minDist);
    
    // Pulsing with music
    cells *= 0.7 + 0.3 * sin(time * 4.0 + minCellId * 6.28 + bass * 8.0);
    
    // Edge detection (cell boundaries)
    float edges = smoothstep(0.05, 0.08, minDist) - smoothstep(0.08, 0.12, minDist);
    edges *= 1.5;
    
    // Dynamic color based on position and cell ID
    float hue = minCellId + time * 0.15 + bass * 0.3;
    float saturation = 0.7 + mid * 0.3;
    float value = cells * (0.5 + bass * 0.5 + high * 0.3);
    
    float3 cellColor = hsv2rgb(fract(hue), saturation, value);
    
    // Edge glow (bright cyan/white)
    float3 edgeColor = mix(
        float3(0.2, 1.0, 0.9),  // Cyan
        float3(1.0, 1.0, 1.0),  // White
        high
    );
    
    float3 color = cellColor + edgeColor * edges * (1.0 + mid * 1.5);
    
    // Add distance-based gradient
    float centerDist = length(uv);
    float gradient = 1.0 - smoothstep(0.0, 2.0, centerDist);
    color *= 0.6 + gradient * 0.4;
    
    // Chromatic aberration on edges (glitch effect)
    if (edges > 0.1 && bass > 0.5) {
        color.r += 0.1 * bass;
        color.b -= 0.05 * bass;
    }
    
    // Vignette
    float vignette = 1.0 - centerDist * 0.3;
    color *= vignette;
    
    // Boost overall brightness
    color *= 1.2;
    
    // Contrast
    color = pow(color, float3(0.9));
    
    return float4(clamp(color, 0.0, 1.5), 1.0);
}

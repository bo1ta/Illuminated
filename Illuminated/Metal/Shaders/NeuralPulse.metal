//
//  NeuralPulse.metal
//  Illuminated
//
//  Created by Alexandru Solomon on 02.02.2026.
//

#include <metal_stdlib>
#include "ShaderTypes.h"
#include "Common.h"

using namespace metal;

struct NeuralVertexOut {
    float4 position [[position]];
    float2 uv;
    float4 color;
};

vertex NeuralVertexOut neuralPulseVertexShader(uint vertexID [[vertex_id]])
{
    NeuralVertexOut out;
    
    // Full screen quad positions
    float2 positions[4] = {
        float2(-1.0, -1.0),  // Bottom-left
        float2( 1.0, -1.0),  // Bottom-right
        float2(-1.0,  1.0),  // Top-left
        float2( 1.0,  1.0)   // Top-right
    };
    
    // UV coordinates (0 to 1)
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

fragment float4 neuralPulseFragmentShader(NeuralVertexOut in [[stage_in]],
                                          constant float *audioData [[buffer(1)]],
                                          constant Uniforms &uniforms [[buffer(2)]])
{
    // Convert UV to centered coordinates
    float2 uv = (in.uv - 0.5) * 2.0; // Now -1 to 1
    uv.x *= uniforms.screenSize.x / uniforms.screenSize.y; // Aspect correction
    
    // Audio processing for neural/bio feel
    float alpha = 0.0, beta = 0.0, gamma = 0.0;
    
    for (int i = 0; i < 256; i += 4) {
        float sample = abs(audioData[i]) * uniforms.amplitude;
        
        // Alpha waves (8-12Hz simulated)
        if (i < 64) alpha += sample * sin(float(i) * 0.1);
        // Beta waves (12-30Hz simulated)
        else if (i < 128) beta += sample * (1.0 + sin(float(i) * 0.2));
        // Gamma waves (30-100Hz simulated)
        else gamma += sample * (1.5 + cos(float(i) * 0.3));
    }
    
    alpha = clamp(alpha / 16.0, 0.0, 2.0);
    beta = clamp(beta / 16.0, 0.0, 2.0);
    gamma = clamp(gamma / 32.0, 0.0, 2.0);
    
    float time = uniforms.time;
    
    // Create neural network grid
    float gridSize = 8.0 + sin(time * 0.3) * 2.0 + alpha * 3.0;
    float2 gridPos = uv * gridSize;
    float2 cell = floor(gridPos);
    float2 fractPos = fract(gridPos) - 0.5;
    
    // Neurons as pulsing nodes
    float neuron = 0.0;
    float connections = 0.0;
    
    // Scan neighbors for neural connections
    for (float y = -1.0; y <= 1.0; y++) {
        for (float x = -1.0; x <= 1.0; x++) {
            float2 neighbor = float2(x, y);
            float2 neighborCell = cell + neighbor;
            
            // Unique hash for each neuron
            float neuronId = sin(neighborCell.x * 12.9898 + neighborCell.y * 78.233) * 43758.5453;
            neuronId = fract(neuronId);
            
            // Neuron activation (responsive to audio)
            float activation = sin(time * 2.0 + neuronId * 6.283 + alpha * 5.0 + beta * 3.0);
            activation = 0.5 + 0.5 * activation;
            
            // Pulsing with brain waves
            activation *= (0.3 + beta * 0.7 + gamma * 0.5);
            
            // Distance to this neuron
            float2 neuronPos = neighbor + 0.5 + 0.2 * sin(time * 0.5 + neuronId * 2.0);
            float dist = length(fractPos - neuronPos);
            
            // Draw neuron node
            float nodeSize = 0.08 + gamma * 0.12 + beta * 0.08;
            float nodeBrightness = 1.0 - smoothstep(0.0, nodeSize, dist);
            nodeBrightness *= activation;
            neuron = max(neuron, nodeBrightness);
            
            // Draw connections (neural pathways)
            if (dist < 1.0) {
                float connection = 1.0 - smoothstep(0.2, 0.8, dist);
                connection *= activation * (0.3 + beta * 0.7);
                connections = max(connections, connection * 0.5);
            }
        }
    }
    
    // Base color: Deep neural blue/purple
    float3 color = float3(0.05, 0.02, 0.08);
    
    // Neurons: Bright electric blue/white with audio response
    float3 neuronColor = float3(0.4, 0.7, 1.0) * neuron * (1.5 + gamma * 1.5);
    
    // Connections: Cyan/green pathways
    float3 connectionColor = float3(0.2, 1.0, 0.8) * connections * (1.0 + alpha * 1.0);
    
    // Brain wave pulses: Purple/magenta energy
    float pulseWave = sin(uv.x * 15.0 + time * 4.0 + sin(uv.y * 10.0) * 3.0);
    pulseWave = 0.5 + 0.5 * pulseWave;
    pulseWave *= (0.2 + beta * 1.2);
    
    float3 pulseColor = float3(1.0, 0.2, 0.6) * pulseWave * 0.6;
    
    // Combine all layers
    color += neuronColor * 2.0;
    color += connectionColor * 1.5;
    color += pulseColor;
    
    // Add scan lines (like EEG monitor)
    float scanLine = sin(in.uv.y * 150.0 + time * 12.0) * 0.5 + 0.5;
    scanLine *= 0.15 * (0.5 + gamma * 0.5);
    color += float3(0.1, scanLine * 0.8, scanLine * 0.6);
    
    // Radial energy burst from center on strong beats
    float centerDist = length(uv);
    float burst = sin(centerDist * 10.0 - time * 5.0 - beta * 10.0) * 0.5 + 0.5;
    burst *= (1.0 - smoothstep(0.0, 2.0, centerDist));
    burst *= beta * 0.3;
    color += float3(burst * 0.5, burst * 0.3, burst);
    
    // Subtle glitch effect on strong signals
    float glitch = step(0.95, fract(time * 5.0 + beta * 10.0));
    color.r += glitch * 0.3 * beta;
    color.g += glitch * 0.1 * beta;
    
    // Boost overall brightness for visibility
    color *= 1.3;
    
    return float4(color, 1.0);
}

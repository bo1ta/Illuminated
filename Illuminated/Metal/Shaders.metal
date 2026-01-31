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

// ============================================================================
// MARK: - Fractal Triangle Preset
// ============================================================================

float3 hsv2rgb(float h, float s, float v) {
    float3 k = float3(1.0, 2.0/3.0, 1.0/3.0);
    float3 p = abs(fract(float3(h, h, h) + k) * 6.0 - 3.0);
    return v * mix(float3(1.0), clamp(p - 1.0, 0.0, 1.0), s);
}

// Triangle SDF (Signed Distance Function)
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
    
    // Audio-reactive modulation
    float audioMod = amplitude * 2.0;
    
    float S = sin(time/3.14) * cos(time*0.125) * (1.0 + audioMod * 0.5);
    float C = cos(time/3.14) * sin(time*0.195) * (1.0 + audioMod * 0.3);
    
    for (int i = 0; i < 8; i++) { // Reduced from 15 for performance
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

vertex VertexOut triangleFractalVertexShader(uint vertexID [[vertex_id]],
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

fragment float4 triangleFractalFragmentShader(VertexOut in [[stage_in]],
                                              constant float *audioData [[buffer(1)]],
                                              constant Uniforms &uniforms [[buffer(2)]])
{
  // Normalize coordinates (-1 to 1)
  float2 position = in.position.xy;
  
  // Correct for aspect ratio
  position.x *= uniforms.screenSize.x / uniforms.screenSize.y;
  
  // Calculate average audio amplitude
  float avgAmplitude = 0.0;
  for (int i = 0; i < 16; i++) {
      avgAmplitude += abs(audioData[i * 64]);
  }
  avgAmplitude = avgAmplitude / 16.0 * uniforms.amplitude;
  
  // Add some audio modulation to time
  float modulatedTime = uniforms.time * (1.0 + avgAmplitude * 0.5);
  
  // Calculate distance field
  float dist = distfunc(position, modulatedTime, avgAmplitude);
  
  // Create black and white pattern
  float pattern = sin(dist * 16.0 + modulatedTime * 8.0) * 0.5 + 0.5;
  
  // Make pattern pulse with audio
  pattern *= 0.8 + avgAmplitude * 0.4;
  
  // Edge glow in white
  float edge = 0.02 / (abs(dist) + 0.01);
  float value = pattern + edge * avgAmplitude;
  
  // Clamp to 0-1
  value = clamp(value, 0.0, 1.0);
  
  // Return grayscale (R=G=B)
  return float4(value, value, value, 1.0);
}

// ============================================================================
// MARK: - Sine Wave Voronoi Preset
// ============================================================================

#define NUMBER_OF_POINTS 80

vertex VertexOut sineVoronoiVertexShader(uint vertexID [[vertex_id]],
                                         constant Uniforms &uniforms [[buffer(2)]])
{
    VertexOut out;
    
    // Create a fullscreen triangle strip (4 vertices)
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
  
  float2 fragCoord = (in.position.xy + 1.0) * 0.5 * uniforms.screenSize;
  
  float2 position = fragCoord / uniforms.screenSize;
  
  float4 color = float4(0.0, 0.0, 0.0, 1.0);
  
  float audioSum = 0.0;
  float audioMax = 0.0;
  
  for (int i = 0; i < 32; i++) {
      int idx = min(1023, i * 32);
      float sample = abs(audioData[idx]) * uniforms.amplitude;
      audioSum += sample;
      audioMax = max(audioMax, sample);
  }
  
  float audioLevel = audioSum / 32.0;
  float audioBeat = smoothstep(0.1, 0.3, audioMax);
  
  float time = uniforms.time * (1.0 + audioLevel * 0.5);
  
  float gridSize = 15.0 + sin(time * 0.5) * 5.0 * audioBeat;
  float2 gridPos = position * gridSize;
  float2 gridIndex = floor(gridPos);
  float2 gridFract = fract(gridPos);
  
  float minDist = 1.0;
  
  for (int y = -1; y <= 1; y++) {
      for (int x = -1; x <= 1; x++) {
          float2 neighbor = float2(float(x), float(y));
          
          float audioOffset = 0.0;
          if (x == 0 && y == 0) {
              int audioIdx = int(gridIndex.x + gridIndex.y) % 32;
              audioOffset = audioData[audioIdx * 32] * uniforms.amplitude * 0.3;
          }
          
          float2 point = 0.5 + 0.5 * sin(time * 0.7 +
                                        neighbor.x * 1.3 +
                                        neighbor.y * 2.1 +
                                        audioOffset);
          
          float2 diff = neighbor + point - gridFract;
          float dist = length(diff);
          
          minDist = min(minDist, dist);
      }
  }
  
  float cells = 1.0 - smoothstep(0.0, 0.1, minDist);
  
  cells *= (0.8 + 0.4 * sin(time * 3.0 + audioLevel * 10.0));
  
  float hue = position.x + position.y * 0.3 + time * 0.1 + audioLevel * 0.5;
  float3 rgbColor = hsv2rgb(fract(hue),
                            0.8 + audioBeat * 0.2,
                            cells * (0.7 + audioLevel * 0.3));
  
  color.rgb = rgbColor;
  
  float edges = 1.0 - smoothstep(0.08, 0.1, minDist);
  edges -= cells;
  color.rgb += float3(0.0, edges * audioBeat, edges * 0.5);
  
  return color;
}

// ============================================================================
// MARK: - Neural Network / Brain Scan
// ============================================================================

vertex VertexOut neuralPulseVertexShader(uint vertexID [[vertex_id]])
{
    VertexOut out;
    
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };
    
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.color = float4(0.0, 0.0, 0.0, 1.0);
    
    return out;
}


fragment float4 neuralPulseFragmentShader(VertexOut in [[stage_in]],
                                          constant float *audioData [[buffer(1)]],
                                          constant Uniforms &uniforms [[buffer(2)]])
{
    float2 uv = in.position.xy;
    uv.x *= uniforms.screenSize.x / uniforms.screenSize.y;
    
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
    
    alpha = alpha / 16.0;
    beta = beta / 16.0;
    gamma = gamma / 32.0;
    
    float time = uniforms.time;
    
    // Create neural network grid
    float gridSize = 12.0 + sin(time * 0.3) * 3.0;
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
            
            // Neuron activation
            float activation = sin(time * 2.0 + neuronId * 6.283 + alpha * 5.0);
            activation = 0.5 + 0.5 * activation;
            
            // Pulsing with brain waves
            activation *= (0.6 + beta * 0.4);
            
            // Distance to this neuron
            float2 neuronPos = neighbor + 0.5 + 0.3 * sin(time * 0.5 + neuronId * 2.0);
            float dist = length(fractPos - neuronPos);
            
            // Draw neuron node
            float nodeSize = 0.1 + gamma * 0.08;
            neuron = max(neuron, 1.0 - smoothstep(0.0, nodeSize, dist));
            
            // Draw connections (neural pathways)
            if (dist < 0.8) {
                float connection = 1.0 - smoothstep(0.3, 0.5, dist);
                connection *= activation * (0.5 + beta * 0.5);
                connections = max(connections, connection);
            }
        }
    }
    
    float3 color = float3(0.02, 0.01, 0.03); // Deep neural blue/black
    
    // Neurons: Electric blue/white
    float3 neuronColor = float3(0.3, 0.6, 1.0) * neuron * (0.8 + gamma * 0.4);
    
    // Connections: Cyan pathways
    float3 connectionColor = float3(0.1, 0.8, 0.7) * connections * (0.7 + alpha * 0.3);
    
    // Brain wave pulses: Purple/red energy
    float pulseWave = sin(uv.x * 20.0 + time * 3.0 + sin(uv.y * 15.0) * 2.0);
    pulseWave = 0.5 + 0.5 * pulseWave;
    pulseWave *= (0.4 + beta * 0.6);
    
    float3 pulseColor = float3(0.8, 0.1, 0.5) * pulseWave * 0.3;
    
    // Combine
    color += neuronColor;
    color += connectionColor;
    color += pulseColor;
    
    // Add scan lines (like EEG monitor)
    float scanLine = sin(uv.y * 200.0 + time * 10.0) * 0.5 + 0.5;
    scanLine *= 0.05 * (0.7 + gamma * 0.3);
    color += float3(0.0, scanLine * 0.5, scanLine);
    
    // Glitch effect on strong signals
    float glitch = step(0.95, fract(time * 5.0 + beta * 10.0));
    uv.x += glitch * (sin(time * 30.0) * 0.02);
    color.r += glitch * 0.2;
    
    return float4(color, 1.0);
}

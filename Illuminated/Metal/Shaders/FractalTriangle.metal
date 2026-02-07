//
//  FractalTriangle.metal
//  Illuminated
//
//  Rewritten again on 07.02.2026 – slower, atmospheric triangle lattice
//  with grain and beat-driven pulses. Grayscale only.
//

#include <metal_stdlib>
#include "ShaderTypes.h"
#include "Common.h"

using namespace metal;

// -----------------------------------------------------------------------------
// Helpers
inline float2x2 rot2(float a) {
    float s = sin(a), c = cos(a);
    return float2x2(c, -s, s, c);
}

inline float hash21(float2 p) {
    p = fract(p * float2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

inline float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float a = hash21(i);
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

inline float fbm1(float2 p) {
    float v = 0.0;
    float a = 0.6;
    float f = 1.5;
    for (int i = 0; i < 4; ++i) {
        v += noise(p * f) * a;
        f *= 2.1;
        a *= 0.5;
    }
    return v;
}

// Distance to repeating equilateral triangle grid.
// Returns small value near edges (used for lines).
inline float triangleGridEdge(float2 p) {
    // Basis for equilateral tiling
    const float2x2 B = float2x2(1.0, 0.5,
                                0.0, 0.8660254); // (1,0) and (1/2, sqrt(3)/2)
    const float2x2 Bi = float2x2(1.0, -0.5773503, // inverse basis
                                 0.0,  1.1547005);

    // Map into triangle lattice coordinates
    float2 q = Bi * p;          // lattice coordinates
    float2 cell = floor(q);
    float2 f = fract(q);

    // Fold to primary triangle when outside
    float3 b = float3(f, 1.0 - f.x - f.y);
    if (b.z < 0.0) {
        // Outside; fold across the longest edge
        float2 f2 = float2(1.0 - f.y, f.x);
        f = f2;
        b = float3(f, 1.0 - f.x - f.y);
    }

    float edge = min(min(b.x, b.y), b.z);
    // Convert back to metric distance (approx)
    return edge * 0.8660254; // scale so width roughly matches world units
}

// -----------------------------------------------------------------------------
// Vertex
vertex VertexOut triangleFractalVertexShader(uint vertexID [[vertex_id]],
                                             constant Uniforms &uniforms [[buffer(2)]]) {
    VertexOut out;
    const float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.color = float4(1.0); // unused
    return out;
}

// -----------------------------------------------------------------------------
// Fragment
fragment float4 triangleFractalFragmentShader(VertexOut in [[stage_in]],
                                              constant float *audioData [[buffer(1)]],
                                              constant Uniforms &uniforms [[buffer(2)]]) {
    // Proper UV setup
    float2 uv = (in.position.xy / uniforms.screenSize) * 2.0 - 1.0;
    uv.x *= uniforms.screenSize.x / uniforms.screenSize.y;

    // Better audio analysis (bass/mid/high)
    float bass = 0.0, mid = 0.0, high = 0.0;
    const int samples = 512;
    for (int i = 0; i < samples; ++i) {
        float s = abs(audioData[i]);
        if (i < 170) bass += s;
        else if (i < 340) mid += s;
        else high += s;
    }
    bass = (bass / 170.0) * uniforms.amplitude;
    mid = (mid / 170.0) * uniforms.amplitude;
    high = (high / 172.0) * uniforms.amplitude;

    float t = uniforms.time;

    // More dramatic rotation with bass
    float rotation = 0.15 * sin(t * 0.15 + bass * 2.0) + t * 0.05;
    uv = rot2(rotation) * uv;
    
    // Camera driftt
    uv += float2(
        0.2 * sin(t * 0.1 + mid * 1.5),
        0.15 * cos(t * 0.08 + bass)
    );

    // Dynamic zoom with bass punch
    float zoom = 1.0 + bass * 0.6 + sin(t * 0.2) * 0.2;
    float2 p = uv * zoom;
    
    // Get triangle edge distance
    float edge = triangleGridEdge(p);

    // Multiple edge layers at different scales
    float edge2 = triangleGridEdge(p * 2.3 + float2(t * 0.1, 0));
    float edge3 = triangleGridEdge(p * 0.5 - float2(0, t * 0.15));

    // Edge detection with audio-reactive width
    float aa = max(1e-3, fwidth(edge));
    float lineWidth = 0.02 + mid * 0.04;
    float lines = 1.0 - smoothstep(lineWidth - aa, lineWidth + aa, edge);
    
    // Secondary thinner lines
    float lines2 = 1.0 - smoothstep(0.01, 0.015, edge2);
    float lines3 = 1.0 - smoothstep(0.015, 0.02, edge3);

    // Interior pattern - multiple frequencies
    float pattern1 = sin(edge * (15.0 + bass * 20.0) - t * (2.0 + mid * 2.0));
    float pattern2 = cos(edge * (30.0 + high * 15.0) + t * 3.0);
    float bands = (pattern1 * 0.6 + pattern2 * 0.4) * 0.5 + 0.5;

    // Flowing energy inside triangles
    float flow = fbm1(p * 1.5 + float2(t * 0.3, -t * 0.2));
    flow += fbm1(p * 3.0 - float2(t * 0.4, t * 0.3)) * 0.5;
    flow = pow(flow, 1.5);

    // Combine patterns
    float interior = mix(bands, flow, 0.4);
    interior *= 0.6 + high * 0.4;

    // Calculate colors
    float3 color = float3(0.0);

    // Base triangle fill - gradient by position
    float hue1 = length(uv) * 0.3 + t * 0.1 + bass * 0.2;
    float3 baseColor = hsv2rgb(
        fract(hue1),
        0.6 + mid * 0.3,
        interior * (0.4 + bass * 0.4)
    );

    // Primary edge glow - cyan/magenta
    float edgeHue = t * 0.15 + edge * 2.0 + mid * 0.3;
    float3 edgeColor = hsv2rgb(
        fract(edgeHue),
        0.8,
        lines * (1.0 + mid * 0.5)
    );

    // Secondary edges - complementary colors
    float3 edge2Color = hsv2rgb(fract(edgeHue + 0.5), 0.7, lines2 * 0.6);
    float3 edge3Color = hsv2rgb(fract(edgeHue + 0.33), 0.6, lines3 * 0.4);

    // Combine layers
    color = baseColor;
    color += edgeColor * 1.5;
    color += edge2Color;
    color += edge3Color;

    // Add energy bursts at intersections
    float intersections = lines * lines2 * 3.0;
    color += float3(1.0, 0.8, 0.3) * intersections * (1.0 + high * 2.0);

    // Radial glow from center
    float centerDist = length(uv);
    float glow = exp(-centerDist * 0.5) * 0.3;
    color += float3(0.3, 0.5, 0.8) * glow * (1.0 + bass * 0.5);

    // Audio-reactive flash
    color += bass * float3(0.2, 0.1, 0.3);
    color += high * float3(0.1, 0.3, 0.4);

    // Vignette
    float vignette = 1.0 - centerDist * 0.4;
    vignette = clamp(vignette, 0.3, 1.0);
    color *= vignette;

    // Brightness boost
    color *= 1.3;
    
    // Contrast
    color = pow(color, float3(0.85));

    return float4(clamp(color, 0.0, 1.8), 1.0);
}

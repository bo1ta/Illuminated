//
//  SpaceCentipede.metal
//  Illuminated
//
//  Created by Alexandru Solomon on 02.02.2026.
//

#include <metal_stdlib>
#include "ShaderTypes.h"
#include "Common.h"

using namespace metal;


float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

float hash_21(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// Rotation matrices
float3x3 rotateX(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return float3x3(
        1.0, 0.0, 0.0,
        0.0, c, -s,
        0.0, s, c
    );
}

float3x3 rotateY(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return float3x3(
        c, 0.0, s,
        0.0, 1.0, 0.0,
        -s, 0.0, c
    );
}

float3x3 rotateZ(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return float3x3(
        c, -s, 0.0,
        s, c, 0.0,
        0.0, 0.0, 1.0
    );
}

// Sphere SDF
float sdSphere(float3 p, float r) {
    return length(p) - r;
}

// Capsule SDF (for centipede segments)
float sdCapsule(float3 p, float3 a, float3 b, float r) {
    float3 pa = p - a;
    float3 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

// Box SDF
float sdBox(float3 p, float3 b) {
    float3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// Centipede segment
float centipedeSegment(float3 p, float t, float segmentIndex) {
    // Main body curve (sinusoidal path through space)
    float curveTime = t * 0.5 + segmentIndex * 0.3;
    
    float3 segmentPos = float3(
        sin(curveTime) * 3.0,
        cos(curveTime * 0.7) * 2.0,
        segmentIndex * 0.8
    );
    
    // Twist the body
    float twist = segmentIndex * 0.2 + t * 0.5;
    
    float3 localP = p - segmentPos;
    
    // Main body segment (capsule)
    float body = sdSphere(localP, 0.5 - segmentIndex * 0.01);
    
    // Legs (6 per segment)
    float legs = 10.0;
    for (int i = 0; i < 6; i++) {
        float legAngle = float(i) * 1.047 + twist; // 60 degrees apart
        float legPhase = sin(t * 3.0 + segmentIndex * 0.5 + float(i));
        
        float3 legStart = localP;
        float3 legEnd = localP - float3(
            cos(legAngle) * (1.0 + legPhase * 0.3),
            sin(legAngle) * (1.0 + legPhase * 0.3),
            0.0
        );
        
        legs = min(legs, sdCapsule(float3(0), legStart, legEnd, 0.08));
    }
    
    return min(body, legs);
}

// Full centipede
float centipede(float3 p, float t) {
    float d = 100.0;
    
    // 20 segments
    for (int i = 0; i < 20; i++) {
        d = min(d, centipedeSegment(p, t, float(i)));
    }
    
    return d;
}

// Black hole
float blackHole(float3 p, float3 pos, float size) {
    return length(p - pos) - size;
}

// Volumetric mist
float mist(float3 p, float t) {
    float n = noise3D(p * 0.5 + t * 0.1);
    n += noise3D(p * 1.0 - t * 0.15) * 0.5;
    return n;
}

// Main scene SDF
float scene(float3 p, float t, float3 blackHolePos, float blackHoleSize, bool includeBlackHole) {
    float d = centipede(p, t);
    
    // Add black hole if active
    if (includeBlackHole) {
        d = min(d, blackHole(p, blackHolePos, blackHoleSize));
    }
    
    return d;
}

// ============================================================================
// MARK: - Shaders
// ============================================================================

vertex RaymarchVertexOut spaceCentipedeVertexShader(uint vertexID [[vertex_id]]) {
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

fragment float4 spaceCentipedeFragmentShader(RaymarchVertexOut in [[stage_in]],
                                            constant float *audioData [[buffer(1)]],
                                            constant Uniforms &uniforms [[buffer(2)]]) {
    // UV setup
    float2 uv = (in.uv - 0.5) * 2.0;
    uv.x *= uniforms.screenSize.x / uniforms.screenSize.y;
    
    float time = uniforms.time;
    
    // Audio analysis
    float bass = 0.0, mid = 0.0, high = 0.0;
    for (int i = 0; i < 32; i++) {
        float sample = abs(audioData[i * 32]);
        if (i < 8) bass += sample;
        else if (i < 20) mid += sample;
        else high += sample;
    }
    bass = (bass / 8.0) * uniforms.amplitude;
    mid = (mid / 12.0) * uniforms.amplitude;
    high = (high / 12.0) * uniforms.amplitude;
    
    // === GLITCH EFFECTS ===
    float glitchStrength = step(0.97, hash(floor(time * 8.0))) * mid;
    if (glitchStrength > 0.0) {
        // RGB split
        uv.x += sin(time * 50.0) * 0.02 * glitchStrength;
        uv.y += cos(time * 43.0) * 0.015 * glitchStrength;
        
        // Scanline offset
        float scanline = floor(in.uv.y * 100.0);
        uv.x += hash(scanline + time) * 0.05 * glitchStrength;
    }
    
    // === CAMERA SETUP ===
    // Camera orbits around centipede but stays focused on it
    float camOrbitSpeed = 0.2; // Slower orbit
    float camOrbitAngle = time * camOrbitSpeed;
    float camDistance = 6.0 + sin(time * 0.2) * 1.0; // Closer and less variation
    
    // Centipede center position (follows the same path as segments)
    float3 centipedeCenter = float3(
        sin(time * 0.5) * 2.0,
        cos(time * 0.35) * 1.5,
        8.0  // Fixed Z distance in front
    );
    
    // Camera orbits around the centipede center
    float3 camPos = centipedeCenter + float3(
        sin(camOrbitAngle) * camDistance,
        cos(camOrbitAngle * 0.7) * camDistance * 0.5 + sin(time * 0.3) * 0.5,
        cos(camOrbitAngle) * camDistance
    );
    
    // Always look at centipede center
    float3 target = centipedeCenter;
    float3 forward = normalize(target - camPos);
    float3 right = normalize(cross(float3(0.0, 1.0, 0.0), forward));
    float3 up = cross(forward, right);
    
    // Camera twist (reduced)
    float twist = sin(time * 0.5 + mid * 2.0) * 0.2; // Less twist
    float3x3 twistMat = rotateZ(twist);
    right = twistMat * right;
    up = twistMat * up;
    
    // Ray direction
    float3 rayDir = normalize(forward + right * uv.x + up * uv.y);
    
    // === BLACK HOLE ===
    bool blackHoleActive = fract(time * 0.3 + hash(floor(time * 0.3))) > 0.7;
    float blackHoleAppear = blackHoleActive ? smoothstep(0.0, 0.5, fract(time * 0.3)) : 0.0;
    
    // Black hole orbits around centipede area
    float3 blackHolePos = centipedeCenter + float3(
        sin(time * 0.4) * 4.0,
        cos(time * 0.3) * 3.0,
        sin(time * 0.5) * 3.0
    );
    float blackHoleSize = 0.8 * blackHoleAppear * (1.0 + bass * 0.5);
    
    // === RAYMARCHING ===
    float t = 0.0;
    float3 color = float3(0.0);
    const int maxSteps = 80;
    bool hit = false;
    
    for (int i = 0; i < maxSteps; i++) {
        float3 pos = camPos + rayDir * t;
        
        float d = scene(pos, time, blackHolePos, blackHoleSize, blackHoleActive);
        
        // Hit detection
        if (d < 0.02) {
            hit = true;
            
            // Normal calculation (for lighting)
            float2 e = float2(0.01, 0.0);
            float3 normal = normalize(float3(
                scene(pos + e.xyy, time, blackHolePos, blackHoleSize, blackHoleActive) -
                scene(pos - e.xyy, time, blackHolePos, blackHoleSize, blackHoleActive),
                scene(pos + e.yxy, time, blackHolePos, blackHoleSize, blackHoleActive) -
                scene(pos - e.yxy, time, blackHolePos, blackHoleSize, blackHoleActive),
                scene(pos + e.yyx, time, blackHolePos, blackHoleSize, blackHoleActive) -
                scene(pos - e.yyx, time, blackHolePos, blackHoleSize, blackHoleActive)
            ));
            
            // Lighting
            float3 lightDir = normalize(float3(1.0, 2.0, -1.0));
            float diffuse = max(dot(normal, lightDir), 0.0);
            
            // Check if hit black hole
            float distToBlackHole = length(pos - blackHolePos);
            bool isBlackHole = blackHoleActive && distToBlackHole < blackHoleSize * 1.5;
            
            if (isBlackHole) {
                // Black hole appearance
                float blackHoleGradient = 1.0 - distToBlackHole / (blackHoleSize * 1.5);
                color = float3(0.1, 0.0, 0.2) * blackHoleGradient;
                color += float3(0.3, 0.1, 0.4) * pow(blackHoleGradient, 3.0);
            } else {
                // Centipede - dark gray/brown with red veins
                float3 baseColor = float3(0.15, 0.12, 0.1);
                
                // Add organic texture
                float organic = noise3D(pos * 5.0);
                baseColor += float3(0.1, 0.05, 0.0) * organic;
                
                // Red veins
                float veins = sin(pos.z * 20.0 + time * 2.0) * sin(pos.x * 15.0);
                veins = smoothstep(0.8, 1.0, veins);
                baseColor += float3(0.3, 0.0, 0.0) * veins * (1.0 + bass);
                
                // Apply lighting
                color = baseColor * (0.3 + diffuse * 0.7);
                
                // Rim lighting
                float rim = pow(1.0 - abs(dot(normal, -rayDir)), 3.0);
                color += float3(0.2, 0.15, 0.3) * rim * 0.5;
            }
            
            break;
        }
        
        // Accumulate mist
        float mistDensity = mist(pos, time) * 0.005;
        color += float3(0.15, 0.15, 0.18) * mistDensity * (1.0 + mid * 0.3);
        
        t += d * 0.7;
        
        if (t > 50.0) break;
    }
    
    // === BLACK HOLE GRAVITATIONAL LENSING ===
    if (blackHoleActive) {
        float3 toBlackHole = blackHolePos - camPos;
        float distToHole = length(toBlackHole);
        float3 dirToHole = normalize(toBlackHole);
        
        float lensing = blackHoleSize / max(distToHole, 1.0);
        lensing *= smoothstep(0.9, 0.0, dot(rayDir, dirToHole));
        
        color = mix(color, float3(0.0), lensing * 0.7);
        color += float3(0.2, 0.1, 0.3) * lensing * 0.3;
    }
    
    // === SPACE BACKGROUND ===
    if (!hit) {
        // Stars
        float stars = 0.0;
        for (int i = 0; i < 100; i++) {
            float3 starDir = normalize(float3(
                hash(float(i) * 12.34) * 2.0 - 1.0,
                hash(float(i) * 45.67) * 2.0 - 1.0,
                hash(float(i) * 78.90) * 2.0 - 1.0
            ));
            
            float starBrightness = pow(max(dot(rayDir, starDir), 0.0), 500.0);
            stars += starBrightness * (0.5 + hash(float(i)) * 0.5);
        }
        
        color += float3(0.8, 0.8, 1.0) * stars * 0.5;
        
        // Deep space gradient
        color += float3(0.01, 0.01, 0.03);
    }
    
    // === POST PROCESSING ===
    
    // Vignette
    float vignette = 1.0 - length(uv) * 0.5;
    vignette = clamp(vignette, 0.2, 1.0);
    color *= vignette;
    
    // RGB chromatic aberration (glitch effect)
    if (glitchStrength > 0.0) {
        // Already offset UVs, just add color distortion
        color.r *= 1.0 + glitchStrength * 0.2;
        color.b *= 1.0 - glitchStrength * 0.15;
    }
    
    // Film grain
    float grain = hash_21(in.uv * time) * 0.03;
    color += grain;
    
    // Darken overall (horror vibe)
    color *= 0.7;
    
    // Audio reactive flash
    color += bass * float3(0.1, 0.0, 0.05);
    
    // Clamp
    color = clamp(color, 0.0, 1.0);
    
    return float4(color, 1.0);
}

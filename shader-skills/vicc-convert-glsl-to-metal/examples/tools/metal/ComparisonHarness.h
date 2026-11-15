#ifndef GLSL_TO_METAL_COMPARISON_HARNESS_H
#define GLSL_TO_METAL_COMPARISON_HARNESS_H

#include <metal_stdlib>
using namespace metal;

// Matches ComparisonUniforms in render-metal.swift: 16 bytes, 8-byte alignment.
struct ComparisonUniforms {
    float2 resolution;
    float time;
    float displayScale;
};

struct ComparisonVertexOut {
    float4 position [[position]];
};

// A single oversized triangle covers the target without an interior seam.
vertex ComparisonVertexOut comparisonVertex(uint vertexID [[vertex_id]]) {
    const float2 positions[3] = {
        float2(-1.0f, -1.0f),
        float2( 3.0f, -1.0f),
        float2(-1.0f,  3.0f)
    };
    return { float4(positions[vertexID], 0.0f, 1.0f) };
}

#endif

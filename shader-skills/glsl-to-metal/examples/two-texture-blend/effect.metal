#include <metal_stdlib>
using namespace metal;

struct BlendUniforms {
    float2 resolution;
    float time;
    float displayScale; // Padding-compatible with the comparison harness.
};
struct BlendVertexOut { float4 position [[position]]; };

vertex BlendVertexOut twoTextureVertex(uint vertexID [[vertex_id]]) {
    const float2 points[] = { float2(-1, -1), float2(3, -1), float2(-1, 3) };
    return { float4(points[vertexID], 0, 1) };
}

float4 blendTextureColor(float2 position, float2 resolution, float time,
                        texture2d<float> first, texture2d<float> second) {
    constexpr sampler imageSampler(coord::normalized, address::clamp_to_edge, filter::linear);
    float2 topLeftUV = position / resolution;
    float2 uv = float2(topLeftUV.x, 1.0f - topLeftUV.y);
    float2 movingUV = topLeftUV * 0.86f + 0.07f
                   + float2(0.04f * sin(time * 0.7f), 0.03f * cos(time * 0.9f));
    float3 a = first.sample(imageSampler, topLeftUV).rgb;
    float3 b = second.sample(imageSampler, movingUV).rgb;
    float boundary = uv.x - 0.5f + 0.16f * sin(uv.y * 8.0f + time);
    float weight = smoothstep(-0.15f, 0.15f, boundary);
    return float4(mix(a, b, weight), 1.0f);
}

fragment float4 twoTextureFragment(BlendVertexOut in [[stage_in]],
                                   constant BlendUniforms &u [[buffer(0)]],
                                   texture2d<float> first [[texture(0)]],
                                   texture2d<float> second [[texture(1)]]) {
    return blendTextureColor(in.position.xy, u.resolution, u.time, first, second);
}

#if defined(COMPARISON_CAPTURE)
#include "../tools/metal/ComparisonHarness.h"
fragment float4 comparisonFragment(ComparisonVertexOut in [[stage_in]],
                                    constant ComparisonUniforms &u [[buffer(0)]],
                                    texture2d<float> first [[texture(0)]],
                                    texture2d<float> second [[texture(1)]]) {
    return blendTextureColor(in.position.xy, u.resolution, u.time, first, second);
}
#endif

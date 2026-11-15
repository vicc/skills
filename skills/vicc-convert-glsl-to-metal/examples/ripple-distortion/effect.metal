#include <metal_stdlib>
using namespace metal;

// Destination-to-source mapping, in the same user-space units as size/amplitude.
[[ stitchable ]] float2 rippleDistortion(float2 position, float2 size,
                                        float time, float amplitude) {
    if (size.x <= 0.0f || size.y <= 0.0f) return position;
    float2 lowerLeft = float2(position.x, size.y - position.y);
    float2 p = (lowerLeft - 0.5f * size) / size.y;
    float radius = length(p);
    float2 direction = p / max(radius, 0.0001f);
    float2 edgeDistance = min(position, size - position);
    float edgeFade = smoothstep(0.0f, 30.0f, min(edgeDistance.x, edgeDistance.y));
    float wave = sin(radius * 42.0f - time * 2.2f) * exp(-radius * 2.0f);
    return position + float2(direction.x, -direction.y) * wave * amplitude * edgeFade;
}

#if defined(COMPARISON_CAPTURE)
#include "../tools/metal/ComparisonHarness.h"
fragment float4 comparisonFragment(ComparisonVertexOut in [[stage_in]],
                                    constant ComparisonUniforms &u [[buffer(0)]],
                                    texture2d<float> input [[texture(0)]]) {
    constexpr sampler imageSampler(coord::normalized, address::clamp_to_edge, filter::linear);
    float2 source = rippleDistortion(in.position.xy, u.resolution, u.time, 7.0f);
    return input.sample(imageSampler, source / u.resolution);
}
#endif

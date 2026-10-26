#include <metal_stdlib>
using namespace metal;

float4 auroraColor(float2 fragCoord, float2 resolution, float time) {
    float2 p = (fragCoord - 0.5f * resolution) / resolution.y;
    float3 color = float3(0.012f, 0.018f, 0.045f);
    for (int i = 0; i < 4; ++i) {
        float n = float(i);
        float center = 0.18f * sin(3.1f * p.x + time * 0.65f + n * 0.62f)
                     + 0.065f * sin(7.0f * p.x - time * 0.4f + n)
                     + (n - 1.5f) * 0.085f;
        float d = abs(p.y - center);
        float ribbon = exp(-d * d * 780.0f) + 0.12f * exp(-d * 12.0f);
        float3 tint = 0.5f + 0.5f * cos(float3(0.0f, 2.0f, 4.0f) + n * 0.9f + p.x);
        color += tint * ribbon * 0.75f;
    }
    color = color / (1.0f + color);
    return float4(color, 1.0f);
}

// SwiftUI ShapeStyle: bounds = .boundingRect, time = .float(seconds).
[[ stitchable ]] half4 auroraRibbons(float2 position, float4 bounds, float time) {
    if (bounds.z <= 0.0f || bounds.w <= 0.0f) return half4(0.0h);
    float2 local = position - bounds.xy;
    float2 fragCoord = float2(local.x, bounds.w - local.y);
    return half4(auroraColor(fragCoord, bounds.zw, time));
}

#if defined(COMPARISON_CAPTURE)
#include "../tools/metal/ComparisonHarness.h"
fragment float4 comparisonFragment(ComparisonVertexOut in [[stage_in]],
                                    constant ComparisonUniforms &u [[buffer(0)]]) {
    // Exercise the exact stitchable entry point, including its half4 rounding.
    return float4(auroraRibbons(in.position.xy, float4(0.0f, 0.0f, u.resolution), u.time));
}
#endif

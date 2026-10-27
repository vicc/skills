#include <metal_stdlib>
using namespace metal;

// GLSL floating-point mod uses floor, not the truncated quotient used by fmod.
// This example calls the helper with finite x and the nonzero divisor 1.0.
float negativeModuloWrap(float x, float y) {
#if defined(COMPARISON_CAPTURE) && defined(MODULO_USE_FMOD) && MODULO_USE_FMOD
    // Deliberately incorrect diagnostic. Never selected in a normal app build.
    return fmod(x, y);
#else
    return x - y * floor(x / y);
#endif
}

float4 negativeModuloColor(float2 fragCoord, float2 resolution, float time) {
    float x = (fragCoord.x - 0.5f * resolution.x) / 64.0f;
    float y = fragCoord.y / 64.0f + time * 0.125f;
    float2 cell = float2(negativeModuloWrap(x, 1.0f), fract(y)) - 0.5f;

    float disc = 1.0f - smoothstep(0.29f, 0.32f, length(cell));
    float inset = 1.0f - smoothstep(0.12f, 0.14f, length(cell - float2(-0.07f, 0.07f)));
    float3 tint = mix(float3(1.0f, 0.49f, 0.37f), float3(0.43f, 0.88f, 0.76f),
                      clamp(fragCoord.y / resolution.y, 0.0f, 1.0f));
    float3 color = mix(float3(0.045f, 0.055f, 0.10f), tint, disc);
    color = mix(color, float3(1.0f, 0.91f, 0.75f), inset * disc * 0.80f);

    float guide = 1.0f - smoothstep(0.5f, 1.5f, abs(fragCoord.x - 0.5f * resolution.x));
    color = mix(color, float3(0.33f, 0.38f, 0.48f), guide * 0.65f);
    return float4(color, 1.0f);
}

// SwiftUI ShapeStyle: bounds = .boundingRect, time = .float(seconds).
[[ stitchable ]] half4 negativeModulo(float2 position, float4 bounds, float time) {
    if (bounds.z <= 0.0f || bounds.w <= 0.0f) return half4(0.0h);
    float2 local = position - bounds.xy;
    float2 fragCoord = float2(local.x, bounds.w - local.y);
    return half4(negativeModuloColor(fragCoord, bounds.zw, time));
}

#if defined(COMPARISON_CAPTURE)
#include "../tools/metal/ComparisonHarness.h"
fragment float4 comparisonFragment(ComparisonVertexOut in [[stage_in]],
                                    constant ComparisonUniforms &u [[buffer(0)]]) {
    // Exercise the actual stitchable function, including its half4 rounding.
    return float4(negativeModulo(in.position.xy, float4(0.0f, 0.0f, u.resolution), u.time));
}
#endif

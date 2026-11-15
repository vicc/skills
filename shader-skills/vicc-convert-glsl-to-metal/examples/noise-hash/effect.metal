#include <metal_stdlib>
using namespace metal;

// Example artwork and integration: MIT license.
// Integer mixer: Chris Wellons's lowbias32, public domain under the Unlicense.
// See README.md for the pinned source and license.
// The default deliberately preserves the source's sine hash. Compile the same
// source with fast or safe/precise settings to compare their actual results.
// NOISE_INTEGER_HASH=1 is an explicit alternative pattern, not a matching fix.
uint noiseHashMix32(uint value) {
    value ^= value >> 16u;
    value *= 0x7feb352du;
    value ^= value >> 15u;
    value *= 0x846ca68bu;
    value ^= value >> 16u;
    return value;
}

float noiseHashSample(float2 cell, float seed) {
#if defined(NOISE_INTEGER_HASH) && NOISE_INTEGER_HASH
    // Inputs are finite, integral, nonnegative, and bounded before conversion.
    uint2 index = uint2(cell);
    uint value = index.x * 0x9e3779b9u;
    value ^= index.y * 0x85ebca6bu;
    value ^= uint(seed) * 0xc2b2ae35u;
    // Exactly representable 24-bit numerator and power-of-two scale.
    return float(noiseHashMix32(value) >> 8u) * (1.0f / 16777216.0f);
#else
    float2 samplePosition = cell + float2(seed * 17.0f, seed * 59.0f);
    return fract(sin(dot(samplePosition, float2(12.9898f, 78.233f))) * 43758.5453f);
#endif
}

float3 noiseHashPalette(float sampleValue) {
    // Exact binary fractions keep the palette out of the precision experiment.
    // Eight color bins show changed cells; smaller hash differences may be hidden.
    if (sampleValue < 0.125f) return float3(0.875f, 0.375f, 0.375f);
    if (sampleValue < 0.250f) return float3(0.96875f, 0.625f, 0.375f);
    if (sampleValue < 0.375f) return float3(0.875f, 0.8125f, 0.375f);
    if (sampleValue < 0.500f) return float3(0.375f, 0.75f, 0.6875f);
    if (sampleValue < 0.625f) return float3(0.375f, 0.5625f, 0.875f);
    if (sampleValue < 0.750f) return float3(0.625f, 0.4375f, 0.875f);
    if (sampleValue < 0.875f) return float3(0.875f, 0.4375f, 0.6875f);
    return float3(0.6875f, 0.75f, 0.875f);
}

float4 noiseHashColor(float2 fragCoord, float time) {
    float2 grid = floor(max(fragCoord, float2(0.0f)) / 16.0f);
    float2 cell = clamp(grid, float2(0.0f), float2(65535.0f));
    float seed = floor(clamp(time, 0.0f, 4095.0f));
    float2 tilePosition = fragCoord - grid * 16.0f;
    bool gap = min(tilePosition.x, tilePosition.y) < 1.0f
            || max(tilePosition.x, tilePosition.y) > 15.0f;
    float3 color = gap ? float3(0.03125f, 0.046875f, 0.09375f)
                      : noiseHashPalette(noiseHashSample(cell, seed));
    return float4(color, 1.0f);
}

// SwiftUI ShapeStyle: bounds = .boundingRect, time = .float(seconds).
// Finite inputs are required. The seed changes at whole seconds, up to 4095.
[[ stitchable ]] half4 noiseHash(float2 position, float4 bounds, float time) {
    if (bounds.z <= 0.0f || bounds.w <= 0.0f) return half4(0.0h);
    float2 local = position - bounds.xy;
    float2 fragCoord = float2(local.x, bounds.w - local.y);
    return half4(noiseHashColor(fragCoord, time));
}

#if defined(COMPARISON_CAPTURE)
#include "../tools/metal/ComparisonHarness.h"
fragment float4 comparisonFragment(ComparisonVertexOut in [[stage_in]],
                                    constant ComparisonUniforms &u [[buffer(0)]]) {
    // Exercise the actual stitchable function, including its half4 output.
    return float4(noiseHash(in.position.xy, float4(0.0f, 0.0f, u.resolution), u.time));
}
#endif

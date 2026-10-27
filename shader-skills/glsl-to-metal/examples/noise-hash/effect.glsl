// Example artwork and integration: MIT license.
// Integer mixer: Chris Wellons's lowbias32, public domain under the Unlicense.
// See README.md for the pinned source and license.
// The capture harness supplies iResolution/iTime.
// The default deliberately preserves a precision-sensitive sine hash.
// NOISE_INTEGER_HASH=1 opts into a different pattern with a uint32 hash.
uint noiseHashMix32(uint value) {
    value ^= value >> 16u;
    value *= 0x7feb352du;
    value ^= value >> 15u;
    value *= 0x846ca68bu;
    value ^= value >> 16u;
    return value;
}

float noiseHashSample(vec2 cell, float seed) {
#if defined(NOISE_INTEGER_HASH) && NOISE_INTEGER_HASH
    // Inputs are finite, integral, nonnegative, and bounded before conversion.
    uvec2 index = uvec2(cell);
    uint value = index.x * 0x9e3779b9u;
    value ^= index.y * 0x85ebca6bu;
    value ^= uint(seed) * 0xc2b2ae35u;
    // Exactly representable 24-bit numerator and power-of-two scale.
    return float(noiseHashMix32(value) >> 8u) * (1.0 / 16777216.0);
#else
    vec2 samplePosition = cell + vec2(seed * 17.0, seed * 59.0);
    return fract(sin(dot(samplePosition, vec2(12.9898, 78.233))) * 43758.5453);
#endif
}

vec3 noiseHashPalette(float sampleValue) {
    // Exact binary fractions keep the palette out of the precision experiment.
    // Eight color bins show changed cells; smaller hash differences may be hidden.
    if (sampleValue < 0.125) return vec3(0.875, 0.375, 0.375);
    if (sampleValue < 0.250) return vec3(0.96875, 0.625, 0.375);
    if (sampleValue < 0.375) return vec3(0.875, 0.8125, 0.375);
    if (sampleValue < 0.500) return vec3(0.375, 0.75, 0.6875);
    if (sampleValue < 0.625) return vec3(0.375, 0.5625, 0.875);
    if (sampleValue < 0.750) return vec3(0.625, 0.4375, 0.875);
    if (sampleValue < 0.875) return vec3(0.875, 0.4375, 0.6875);
    return vec3(0.6875, 0.75, 0.875);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 grid = floor(max(fragCoord, vec2(0.0)) / 16.0);
    vec2 cell = clamp(grid, vec2(0.0), vec2(65535.0));
    float seed = floor(clamp(iTime, 0.0, 4095.0));
    vec2 tilePosition = fragCoord - grid * 16.0;
    bool gap = min(tilePosition.x, tilePosition.y) < 1.0
            || max(tilePosition.x, tilePosition.y) > 15.0;
    vec3 color = gap ? vec3(0.03125, 0.046875, 0.09375)
                     : noiseHashPalette(noiseHashSample(cell, seed));
    fragColor = vec4(color, 1.0);
}

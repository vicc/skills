// Original MIT-licensed example. The capture harness supplies iResolution/iTime.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // The center line is x = 0. Pixel centers divided by 64 are exactly
    // representable at the published capture size, keeping this a modulo test.
    float x = (fragCoord.x - 0.5 * iResolution.x) / 64.0;
    float y = fragCoord.y / 64.0 + iTime * 0.125;
    vec2 cell = vec2(mod(x, 1.0), fract(y)) - 0.5;

    float disc = 1.0 - smoothstep(0.29, 0.32, length(cell));
    float inset = 1.0 - smoothstep(0.12, 0.14, length(cell - vec2(-0.07, 0.07)));
    vec3 tint = mix(vec3(1.0, 0.49, 0.37), vec3(0.43, 0.88, 0.76),
                    clamp(fragCoord.y / iResolution.y, 0.0, 1.0));
    vec3 color = mix(vec3(0.045, 0.055, 0.10), tint, disc);
    color = mix(color, vec3(1.0, 0.91, 0.75), inset * disc * 0.80);

    // A subtle guide marks the sign change, independently of modulo.
    float guide = 1.0 - smoothstep(0.5, 1.5, abs(fragCoord.x - 0.5 * iResolution.x));
    color = mix(color, vec3(0.33, 0.38, 0.48), guide * 0.65);
    fragColor = vec4(color, 1.0);
}

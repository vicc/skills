// Original MIT-licensed example. The capture harness supplies iResolution/iTime.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = (fragCoord - 0.5 * iResolution) / iResolution.y;
    vec3 color = vec3(0.012, 0.018, 0.045);
    for (int i = 0; i < 4; ++i) {
        float n = float(i);
        float center = 0.18 * sin(3.1 * p.x + iTime * 0.65 + n * 0.62)
                     + 0.065 * sin(7.0 * p.x - iTime * 0.4 + n)
                     + (n - 1.5) * 0.085;
        float d = abs(p.y - center);
        float ribbon = exp(-d * d * 780.0) + 0.12 * exp(-d * 12.0);
        vec3 tint = 0.5 + 0.5 * cos(vec3(0.0, 2.0, 4.0) + n * 0.9 + p.x);
        color += tint * ribbon * 0.75;
    }
    color = color / (1.0 + color);
    fragColor = vec4(color, 1.0);
}

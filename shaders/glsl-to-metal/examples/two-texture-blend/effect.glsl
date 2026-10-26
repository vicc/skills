// Two independent opaque images, both with the top row at texture v=0.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution;
    vec2 topLeftUV = vec2(uv.x, 1.0 - uv.y);
    vec2 movingUV = topLeftUV * 0.86 + 0.07
                  + vec2(0.04 * sin(iTime * 0.7), 0.03 * cos(iTime * 0.9));
    vec3 a = texture(iChannel0, topLeftUV).rgb;
    vec3 b = texture(iChannel1, movingUV).rgb;
    float boundary = uv.x - 0.5 + 0.16 * sin(uv.y * 8.0 + iTime);
    float weight = smoothstep(-0.15, 0.15, boundary);
    fragColor = vec4(mix(a, b, weight), 1.0);
}

// iChannel0 is an opaque image, with its top row at texture v=0.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = (fragCoord - 0.5 * iResolution) / iResolution.y;
    float radius = length(p);
    vec2 direction = p / max(radius, 0.0001);
    vec2 topLeft = vec2(fragCoord.x, iResolution.y - fragCoord.y);
    vec2 edgeDistance = min(topLeft, iResolution - topLeft);
    float edgeFade = smoothstep(0.0, 30.0, min(edgeDistance.x, edgeDistance.y));
    float wave = sin(radius * 42.0 - iTime * 2.2) * exp(-radius * 2.0);
    vec2 offset = vec2(direction.x, -direction.y) * wave * 7.0 * edgeFade;
    fragColor = texture(iChannel0, (topLeft + offset) / iResolution);
}

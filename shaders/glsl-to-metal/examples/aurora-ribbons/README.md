# Aurora ribbons

![GLSL and Metal comparison](comparison.png)

Four animated procedural ribbons, implemented as a SwiftUI shader fill. No textures or source view are required.

- [GLSL](effect.glsl) uses lower-left pixel coordinates and aspect-corrects by viewport height.
- [Metal](effect.metal) exposes `auroraRibbons` as a stitchable `ShapeStyle`. It flips SwiftUI's top-left Y coordinate before calling the same effect math. Because the coordinates are normalized by height, a uniform point-to-pixel scale cancels out.
- [SwiftUIExamples.swift](../SwiftUIExamples.swift) includes `AuroraRibbonsExample(time:)` and `AnimatedAuroraExample()`. Add this `.metal` file to the app target without `COMPARISON_CAPTURE`.

```swift
AuroraRibbonsExample(time: 1.25)
    .frame(width: 640, height: 400)
```

The animated wrapper pauses when hidden, inactive, or under Reduce Motion. Both time frequencies repeat after `40 * pi` seconds, so the wrapper reduces that period before converting to Float. Recreating the view's identity restarts it.

The capture calls the actual stitchable function, including its `half4` output rounding. The largest observed channel difference is 1/255; see [metrics.json](metrics.json). All output pixels are opaque, so this example does not test transparency.

**Targets:** iOS 17+ / native macOS 14+. Both minimum targets compiled; actual GPU captures ran on macOS 26.7.1, Apple M3 Max. No iOS runtime or minimum-OS runtime was tested. See the shared [support/testing table](../README.md#supported-targets-and-actual-testing) and [capture methodology](../README.md#capture-conditions-and-measured-differences).

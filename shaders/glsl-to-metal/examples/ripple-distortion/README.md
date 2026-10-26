# Ripple distortion

![GLSL and Metal comparison](comparison.png)

A radial wave displaces sampling positions in an asymmetric grid image. The colored corner markers make an accidental Y flip easy to spot.

- [GLSL](effect.glsl) calculates the source texture coordinate for each destination pixel.
- [Metal](effect.metal) exposes that same inverse mapping as `rippleDistortion`, a SwiftUI `distortionEffect` returning a source position.
- [SwiftUIExamples.swift](../SwiftUIExamples.swift) provides `RippleDistortionExample(image:time:amplitude:)`. Add this `.metal` file to the app target, and add [grid.png](../assets/grid.png) to an image asset named `ComparisonGrid`.

```swift
RippleDistortionExample(image: Image("ComparisonGrid"), time: 1.25, amplitude: 7)
    .frame(width: 640, height: 400)
```

The wave's displacement is bounded by `abs(amplitude)` on each axis, which supplies `maxSampleOffset`. The edge fade reduces displacement near the boundary. In SwiftUI, amplitude and the 30-unit edge fade are in points. In the comparison harness, one user-space unit equals one pixel. To match physical pixels at 2×/3×, scale both these distances and the rendered view dimensions accordingly; the fixed captures do not establish Retina pixel parity.

The capture calls the actual stitchable position function and samples an opaque texture with linear/clamp sampling. SwiftUI's own layer rasterization and edge behavior are outside this comparison. The largest observed channel difference is 1/255; see [metrics.json](metrics.json).

**Targets:** iOS 17+ / native macOS 14+. Both minimum targets compiled; actual GPU captures ran on macOS 26.7.1, Apple M3 Max. No iOS runtime or minimum-OS runtime was tested. See the shared [support/testing table](../README.md#supported-targets-and-actual-testing).

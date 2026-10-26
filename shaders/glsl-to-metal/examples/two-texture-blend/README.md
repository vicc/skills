# Two-texture blend

![GLSL and Metal comparison](comparison.png)

A moving, feathered boundary blends two independent textures. This example uses a small Metal render pipeline because SwiftUI's shader interface currently accepts only one image argument per shader instance. [Apple's image-argument contract](https://developer.apple.com/documentation/swiftui/shader/argument/image(_:)).

- [GLSL](effect.glsl) samples `iChannel0` and `iChannel1`, with the first PNG row at texture `v = 0`.
- [Metal](effect.metal) has production `twoTextureVertex` and `twoTextureFragment` functions. Its comparison wrapper calls the same `blendTextureColor` helper.
- [TwoTextureBlendView.swift](TwoTextureBlendView.swift) is a complete SwiftUI/MetalKit bridge, using `NSViewRepresentable` on native macOS and `UIViewRepresentable` on iOS. It retains the renderer, uses drawable pixels, redraws on changes, and presents setup failures in SwiftUI.

Add the Swift and `.metal` files to the app target. Add [grid.png](../assets/grid.png) and [stripes.png](../assets/stripes.png) as ordinary bundled files with target membership. Use their resource URLs, for example inside a view's body:

```swift
if let first = Bundle.main.url(forResource: "grid", withExtension: "png"),
   let second = Bundle.main.url(forResource: "stripes", withExtension: "png") {
    TwoTextureBlendView(firstTextureURL: first, secondTextureURL: second, time: 1.25)
        .frame(width: 640, height: 400)
} else {
    Text("Add grid.png and stripes.png to the app target.")
}
```

The view takes an explicit time. A caller may update it from a timeline without recreating the pipeline; keep time fixed for comparisons. The input images are opaque, loaded without sRGB decoding, and sampled with linear filtering and clamp-to-edge addressing.

The offscreen capture uses RGBA8 UNORM; the onscreen `MTKView` uses BGRA8 UNORM, an allowed `CAMetalLayer` drawable format. The channel storage order changes, while the numeric unorm components retain the same meaning. Window compositing may apply additional color management. [Apple drawable pixel formats](https://developer.apple.com/documentation/quartzcore/cametallayer/pixelformat).

The largest observed capture difference is 1/255; see [metrics.json](metrics.json). The captures exercise the shared shader math and texture inputs, not live SwiftUI resizing or display migration.

**Targets:** iOS 17+ / native macOS 14+. Both minimum targets compiled in Swift 6 mode; actual GPU captures ran on macOS 26.7.1, Apple M3 Max. The UIKit branch is intended for iOS/Catalyst, but only the iOS target was compiled. No iOS, Catalyst, Intel Mac, or minimum-OS runtime was tested. See the shared [support/testing table](../README.md#supported-targets-and-actual-testing).

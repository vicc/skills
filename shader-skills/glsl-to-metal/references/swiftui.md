# SwiftUI shader contracts

Use this reference when choosing or implementing SwiftUI integration. Confirm availability against the target SDK when using newer APIs.

## Function signatures

These are signature patterns, not complete implementations: replace `args...` with the actual explicit argument declarations. Include `<metal_stdlib>` and use the `metal` namespace; include `<SwiftUI/SwiftUI.h>` when using `SwiftUI::Layer`.

| Use | Required Metal signature pattern | SwiftUI integration |
| --- | --- | --- |
| Procedural fill | `[[ stitchable ]] half4 name(float2 position, args...)` | `Shape.fill(shader)` or a compatible `foregroundStyle(shader)` |
| Color filter | `[[ stitchable ]] half4 name(float2 position, half4 color, args...)` | `.colorEffect(shader)` |
| Distortion | `[[ stitchable ]] float2 name(float2 position, args...)` | `.distortionEffect(shader, maxSampleOffset: bound)` |
| Layer filter | `[[ stitchable ]] half4 name(float2 position, SwiftUI::Layer layer, args...)` | `.layerEffect(shader, maxSampleOffset: bound)` |

SwiftUI supplies the leading position/color/layer values. Bind only the remaining arguments, in order, using the matching `Shader.Argument` types. Use the color-bearing forms' required premultiplied output. Distortion returns the source position to sample for the current destination, not a forward displacement of source vertices.

These core APIs are available on iOS 17 and macOS 14. A shader passed to a fill has a different signature from a color filter; they are not interchangeable merely because both return `half4`.

Sources: [Shader](https://developer.apple.com/documentation/swiftui/shader), [colorEffect](https://developer.apple.com/documentation/swiftui/view/coloreffect(_:isenabled:)), [distortionEffect](https://developer.apple.com/documentation/swiftui/view/distortioneffect(_:maxsampleoffset:isenabled:)), [layerEffect](https://developer.apple.com/documentation/swiftui/view/layereffect(_:maxsampleoffset:isenabled:)).

## Inputs and boundaries

- `.image` binds a `texture2d<half>`. Apple's current contract permits only one image parameter per `Shader` instance. `SwiftUI::Layer` is a separate view-content input, not arbitrary access to multiple Shadertoy channels.
- `layer.sample(position)` samples in user space and returns filtered, premultiplied color. Do not substitute normalized texture UVs for its position argument.
- `.boundingRect` provides `float4(x, y, width, height)`; use `.zw` for size and account for the origin. It is undefined in contexts without natural bounds, so pass explicit dimensions there.
- Array/data arguments can expand into a pointer plus count/byte-size parameters. Check their documented ABI rather than assuming one Swift argument always maps to one Metal parameter.
- SwiftUI effects may not capture AppKit/UIKit-backed content and can show a placeholder. Check the actual view composition before promising effects on an embedded `MTKView`, web view, or other platform view; do not assume `drawingGroup()` fixes this boundary.

Sources: [image argument](https://developer.apple.com/documentation/swiftui/shader/argument/image(_:)), [boundingRect](https://developer.apple.com/documentation/swiftui/shader/argument/boundingrect), [arguments](https://developer.apple.com/documentation/swiftui/shader/argument), [layerEffect](https://developer.apple.com/documentation/swiftui/view/layereffect(_:maxsampleoffset:isenabled:)).

## Loading and scheduling

Ensure `.metal` files compile into the library used by the shader call. `ShaderLibrary.default` addresses the app's main bundle. For a Swift package or framework, use the correct bundle/library, such as `.bundle(.module)` when the package actually provides that resource bundle. Do not assume `.module` exists in ordinary app targets.

Use view-local dimensions and display scale. For SwiftUI animation, `TimelineView(.animation)` can schedule redraws, but its dates alone do not establish elapsed time: retain a stable origin. Keep time/phase updates separate from expensive resource creation.

Sources: [ShaderLibrary](https://developer.apple.com/documentation/swiftui/shaderlibrary), [TimelineView](https://developer.apple.com/documentation/swiftui/timelineview).

## Optional refinements

For an effect sensitive to first-use stalls, consider `Shader.compile(as:)` on iOS 18/macOS 15 or later, guarded when older targets are supported. Precompile before first presentation using the same usage (`.shapeStyle`, `.colorEffect`, `.distortionEffect`, or `.layerEffect`) and argument types as rendering. Handle failures and do not recompile on each frame. Successful precompilation checks the current GPU's compilation path, not visual fidelity.

For smooth color gradients, consider `dithersColor` when banding is visible. Do not silently introduce dithering into an effect whose exact pixel output matters.

Sources: [compile(as:)](https://developer.apple.com/documentation/swiftui/shader/compile(as:)), [dithersColor](https://developer.apple.com/documentation/swiftui/shader/ditherscolor).

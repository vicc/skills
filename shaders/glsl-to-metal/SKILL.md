---
name: glsl-to-metal
description: Convert GLSL fragment shaders and Shadertoy effects into Metal for iOS and macOS, using SwiftUI stitchable shaders where suitable and a Metal renderer when needed. Use for shader ports or explicitly requested reconstructions of web shader effects.
---

# GLSL to Metal

Preserve the source effect while making coordinates, inputs, color handling, and integration explicit. Focus on iOS and macOS; verify support separately for other Apple platforms. Prefer a focused implementation over an engine or unrelated app scaffolding.

## Choose the integration

Use the project's platform, deployment target, and architecture. For standalone examples, state a deployment target supported by every API used. Do not silently raise an app's minimum OS version. SwiftUI's core shader APIs start at iOS 17 and macOS 14; older targets need availability handling or another rendering path.

Prefer a SwiftUI `[[ stitchable ]]` shader when the effect fits:

- A `Shader` used as a `ShapeStyle` for procedural fills without source content.
- `colorEffect` for transformations of the current pixel's color.
- `distortionEffect` for mapping each destination position to a source sampling position.
- `layerEffect` for sampling the view's rendered layer, including neighboring pixels.

Before writing a SwiftUI shader, read [SwiftUI contracts and integration](references/swiftui.md) for signatures, resource limits, bundling, and optional precompilation.

Texture use alone does not require a custom pipeline, but SwiftUI currently supports only one `.image` argument per shader instance. Check whether that plus any supplied layer covers the inputs. Use a Metal renderer for persistent feedback, multiple independent texture inputs that exceed SwiftUI's bindings, explicit render/compute passes, or unsupported blending. Do not flatten a multipass effect into a single pass without identifying the visual change.

Before implementation, consult current official Apple documentation for the APIs actually used. Use Apple Doc MCP if available; otherwise use official web documentation or the installed SDK. For non-Apple dependencies, use Context7 if available or official documentation. No particular MCP server is required. Identify unverified API assumptions when documentation is inaccessible.

## Inspect the source

Identify plain GLSL, Shadertoy `mainImage`, or a requested reconstruction. Inventory uniforms, channel types, textures, sampler settings, time, mouse input, resolution, buffer passes, and feedback dependencies. Account for used Shadertoy values such as `iTimeDelta`, `iFrame`, and `iChannelResolution`, not just `iTime` and `iResolution`.

Map each used input to a concrete Swift/Metal value, texture, or pass. Preserve channel wrapping, filtering, mipmap/LOD behavior, texture orientation, and data-versus-color interpretation where they affect the result. Do not replace required channels with unrelated procedural noise and call the port equivalent.

Inspect linked source when accessible. For incomplete source, infer only the smallest necessary pieces and label them. If only a visible demo is available, call the result a reconstruction; if that is also inaccessible, request source or a visual reference. Preserve attribution and license notices: this skill's license does not relicense third-party shaders or assets.

## Convert deliberately

### Coordinates and platform input

Explain the mapping of `fragCoord`, UVs, resolution, aspect correction, origins, Y direction, and rotation pivots where used. SwiftUI positions are in user space, not necessarily drawable pixels. Keep position and resolution in the same units. For pixel-dependent effects, use the actual view's display scale or drawable dimensions; do not assume the main screen's scale describes a Mac window on another display.

GLSL fragment coordinates typically start at the lower left, but check source conventions before flipping Y. Match pixel centers when relevant. Subtract the center before centered rotation, preserve the source's aspect-correction order, and guard zero-sized layouts. For interactive shaders, translate touch or pointer positions into the same coordinate system; preserve any used Shadertoy mouse press/click-origin semantics.

### Types and math

- Map `vec2/3/4` to `float2/3/4` and `mat2/3/4` to `float2x2/3x3/4x4`. Check constructors, column layout, and multiplication order. GLSL matrix `*` and component-wise `matrixCompMult` are distinct operations.
- GLSL floating-point `mod(x, y)` is `x - y * floor(x / y)`. Metal `fmod` differs for negative operands. Use a typed helper when needed; use `fmod` only where equivalent over the actual input domain.
- Map two-argument `atan(y, x)` to `atan2(y, x)`; keep one-argument `atan(x)`.
- Check overloads and scalar/vector types for builtins actually used. Translate GLSL `out`/`inout` helpers into valid Metal references with the correct address space, rather than leaving GLSL parameter qualifiers behind.
- Translate texture sampling, precision qualifiers, and derivatives for the chosen execution context. `dFdx`/`dFdy` map to `dfdx`/`dfdy` where supported; check derivative orientation after coordinate changes and do not assume fragment derivatives work in compute kernels.
- Preserve recognizable parameter names. Use `float` for procedural and coordinate math unless reduced precision is justified; return the type required by the API.

Remove GLSL-only builtins and declarations. Flag undefined source math that materially affects the port, including reversed/equal `smoothstep` edges, zero-length normalization, or invalid `pow` domains. If regularizing such behavior, explain the intended approximation rather than silently changing the effect.

### Color and alpha

Parse hex colors and URL parameters explicitly, including alpha. Normalizing 8-bit sRGB values is not a conversion to linear light. Track the source and destination color spaces, texture formats, and any transfer functions already present; avoid double conversion and do not gamma-correct data textures.

SwiftUI color-bearing shaders use premultiplied colors in the destination color space. Account for zero alpha when unpremultiplying, and do not premultiply an already-premultiplied `.color` argument again. A custom renderer's output must agree with its render-target format and blend factors. Preserve intentional HDR values instead of automatically clamping them. Expose useful colors in Swift with the user's defaults.

### Animation and performance

Wire elapsed time and speed explicitly, with a stable origin and a documented pause/resume policy. Keep frame-dependent feedback separate from elapsed time. Show how redraws are scheduled; respect Reduce Motion and the app's lifecycle rather than assuming a fixed frame rate. For long-running effects, address loss of float time precision without wrapping time in a way that introduces a discontinuity.

For layer/distortion effects, derive `maxSampleOffset` per axis in user-space units from all allowed parameter values. This sampling bound does not itself enlarge layout or guarantee visible output beyond a view's bounds; explain padding/clipping as needed. Profile expensive loops and sampling on representative hardware before claiming performance.

## When a Metal renderer is needed

Use `MTKView` when appropriate. For SwiftUI integration, use `UIViewRepresentable` on iOS and `NSViewRepresentable` on native macOS; Mac Catalyst follows UIKit. Share rendering code and isolate platform-specific view/input adapters. Only produce the platforms requested.

- Retain the renderer/delegate, update parameters without recreating pipelines every frame, and release or stop rendering work when the view is dismantled. Respect UI actor isolation and the actual delegate callback model.
- Use `drawableSize` in pixels for viewport uniforms. Handle resize and backing-scale changes, unavailable drawables/devices, and zero-sized views. On macOS, test resizing and movement between displays.
- Match Swift/Metal uniform layout and alignment, texture usage, resource bindings, color formats, and blending. Avoid overwriting resources still in use by the GPU; choose synchronization/storage appropriate to the supported GPU families rather than assuming every Mac has Apple silicon's memory behavior.
- For feedback, use separate read/write textures, define initial contents, preserve pass order, and define reset or resampling on resize. Do not sample an attachment while writing it as a substitute for previous-frame storage.
- Choose Metal language features and APIs supported by the deployment target and GPU families. Newer APIs such as Metal 4 are optional, not a prerequisite for these ports; check capability requirements before adopting them.

## Deliver and validate

Provide a brief integration summary, a complete `.metal` file, Swift integration with a minimal view, and concise notes on preserved behavior, differences, limitations, and tunable parameters. Include necessary imports, target membership or bundle selection, and availability handling. Do not present undefined helpers or placeholder resources as a complete implementation.

Check input coverage, coordinate units, aspect ratio, time, sampling bounds, alpha, and Swift/Metal signatures. When the toolchain is available, compile for the requested platforms and stated targets, recording the result; otherwise explicitly report a static review. Dynamic shader lookup means a successful Swift build alone does not prove the Metal function name or argument bindings are valid at runtime.

When source rendering is available, compare at matching inputs/time, different aspect ratios, and transparency where applicable. Validate any macOS claim on macOS and any iOS claim on iOS. Distinguish compilation, shader loading/binding, visual comparison, and device performance; claim only checks actually performed.

## Language references

- [Metal Shading Language specification](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf)
- [GLSL specification](https://registry.khronos.org/OpenGL/specs/gl/GLSLangSpec.4.60.html)
- [Metal capabilities](https://developer.apple.com/metal/capabilities/)
- [MTKView drawable size](https://developer.apple.com/documentation/metalkit/mtkview/drawablesize)
- [NSViewRepresentable](https://developer.apple.com/documentation/swiftui/nsviewrepresentable) and [UIViewRepresentable](https://developer.apple.com/documentation/swiftui/uiviewrepresentable)

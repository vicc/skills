# Numerical precision and fast math

Use this reference when a port changes a noise pattern, develops seams at negative coordinates, or depends on sensitive floating-point calculations.

## Tiny math changes can become visible

A common shader hash takes a sine result, multiplies it by a large constant, then keeps the fractional part. Small changes to `sin`, intermediate rounding, or expression evaluation can change that fraction and produce a different pattern. Keep the source expression, input types, seed, and coordinate mapping visible while investigating.

Using `float` avoids unnecessary `half` precision loss, but does not promise matching GLSL results. Precise functions and conservative optimizations can help diagnose a mismatch; they do not guarantee identical output across languages, compilers, or GPUs.

Check function-specific accuracy ranges as well as finite inputs. The Metal specification gives fast `sin` a tight absolute-error bound over `[-pi, pi]` and permits larger error outside it. Its fast `fmod` accuracy is unspecified, so use precise functions when isolating the modulo wrapping rule. These are accuracy limits, not a reason to silently clamp or wrap the source hash's inputs. See section 8.4, Tables 8.1 and 8.2 of the [Metal language specification](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf).

## Check two separate math settings

Metal separates arithmetic optimizations from the default single-precision math functions:

| Setting | What it changes | Diagnostic comparison |
| --- | --- | --- |
| Math mode | Whether the compiler may make unsafe floating-point transformations | `fast` versus `safe` |
| FP32 math functions | Whether unqualified math calls select the `metal::fast` or `metal::precise` implementation | `fast` versus `precise` |

For the compiler used by these examples, the explicit command-line pairs are:

```sh
# Fast arithmetic and fast FP32 functions.
-fmetal-math-mode=fast -fmetal-math-fp32-functions=fast

# Conservative arithmetic and precise FP32 functions.
-fmetal-math-mode=safe -fmetal-math-fp32-functions=precise
```

These are compiler arguments, not standalone shell commands. Check `xcrun -sdk macosx metal --help` for the installed toolchain before using them. Compiler support is separate from the app's OS deployment target and selected Metal language version. Record both flags rather than relying on an unspecified default. Comparing these pairs changes two settings together; isolate one at a time before attributing a difference to a particular setting.

For Metal source compiled at runtime, `MTLCompileOptions.mathMode` and `mathFloatingPointFunctions` expose the corresponding choices on iOS 18/macOS 15 and later. Check availability and the installed SDK when supporting older targets; the legacy `fastMathEnabled` property is deprecated in favor of the newer options. Runtime defaults can depend on the language standard version.

For bundled `.metallib` files, including SwiftUI shaders loaded from a library, apply settings when compiling the Metal source. Setting options on a separate runtime compilation does not rewrite an already compiled library. Confirm which library the app actually loads.

Choose settings based on observed fidelity needs, then measure performance on the target device. Do not disable optimizations across an entire app merely because one shader uses noise.

Sources: [math mode](https://developer.apple.com/documentation/metal/mtlcompileoptions/mathmode), [FP32 functions](https://developer.apple.com/documentation/metal/mtlcompileoptions/mathfloatingpointfunctions), [legacy fast math](https://developer.apple.com/documentation/metal/mtlcompileoptions/fastmathenabled), and [Apple's explanation of fast-math transformations](https://developer.apple.com/videos/play/wwdc2016/606/). Flag spellings were checked against the example toolchain's `metal --help`; API availability was checked against its Metal SDK headers.

## Compare the behavior that matters

- Match dimensions, pixel centers, time, seed, uniforms, textures, and output format before changing math settings. Keep hash calculations in the same precision on both sides.
- For negative modulo, include coordinates below and above zero and around wrap boundaries. GLSL `mod(x, y)` uses `x - y * floor(x / y)`; Metal `fmod` uses a truncated quotient. Keep the divisor nonzero and check the actual operand domain. A floor-based helper preserves the intended wrapping rule, not every possible floating-point rounding result.
- For sine hashes, capture the original GLSL expression against each explicit Metal configuration. Keep the measured mismatch even if precise mode fails to improve it. Match the app's final build settings when validating its output.
- A matching unsigned-integer hash can provide a useful control when both implementations use the same defined operations, seed conversion, and output mapping. It changes the source pattern. Explain that visual change and get the user's agreement before using it as a replacement.
- Record source hashes, compiler settings, hardware, and results. Test the requested platform rather than extending a Mac result to an iPhone. No math mode alone establishes cross-GPU identity or performance.

See the [negative-modulo comparison](../examples/negative-modulo/README.md) and [noise-hash comparison](../examples/noise-hash/README.md) for concrete inputs and recorded captures. The [GLSL specification](https://registry.khronos.org/OpenGL/specs/gl/GLSLangSpec.4.60.html#common-functions) defines the floor-based modulo rule and notes that implementation rounding can still affect results.

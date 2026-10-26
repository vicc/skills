# GLSL to Metal

An agent skill for converting GLSL fragment shaders and Shadertoy effects into Metal for **iOS and macOS**.

The skill prefers SwiftUI stitchable shaders when suitable. It uses a small Metal renderer when an effect needs feedback, additional texture inputs, explicit passes, or other capabilities outside SwiftUI's shader interface.

## What to provide

- The GLSL source and any helper functions.
- Every used texture, channel assignment, sampler setting, and buffer pass.
- The target platform and deployment version, or an existing project to inspect.
- Any behavior or parameters that must remain unchanged.

For a reconstruction, provide an accessible demo or visual reference and describe its motion. The agent should distinguish a reconstruction from a literal source translation.

## Use

Install using the [repository instructions](../../README.md), then ask:

```text
Use $glsl-to-metal to convert this Shadertoy effect for my native
macOS SwiftUI app. Keep window resizing and display scaling correct,
preserve its inputs, and show a minimal view that renders it.
```

Expect a `.metal` file, Swift integration, a minimal view, and notes on differences and tunable parameters.

## Scope and requirements

SwiftUI's core shader APIs start at **iOS 17 and macOS 14**. The skill follows the app's deployment target and checks newer APIs separately. Older targets may need another rendering path. Other Apple platforms require their own availability checks.

No specific MCP server or third-party Swift package is required. Apple Doc MCP and Context7 are optional documentation tools; official web documentation or the installed SDK can serve as alternatives. Compiling generated code requires a compatible Xcode installation and Apple SDK.

These are agent instructions, not a shader compiler or rendering library. Every generated port still needs appropriate build, visual, and performance validation. A successful Swift build alone does not establish runtime shader bindings or visual fidelity.

## Examples and tested versions

The [example gallery](examples/README.md) includes a procedural fill, a ripple distortion, and a two-texture renderer, each with side-by-side GLSL/Metal captures, source code, and reproduction commands.

All app-facing example Swift and Metal compiled for **arm64 iOS 17 and macOS 14**. Actual captures ran on **macOS 26.7.1 with an Apple M3 Max**, using Xcode 27.1. No iOS runtime, Intel Mac, or execution on the minimum OS releases was tested. The [full testing table](examples/README.md#supported-targets-and-actual-testing) distinguishes deployment targets, compilation, and runtime evidence.

## Files

- [SKILL.md](SKILL.md): conversion workflow and requirements.
- [references/swiftui.md](references/swiftui.md): shader signatures, resource limits, library loading, and optional refinements.
- [agents/openai.yaml](agents/openai.yaml): Codex display metadata and invocation prompt.
- [examples/](examples/README.md): original shader pairs, Swift integration, and actual GPU comparisons.

See [contribution guidance](../../CONTRIBUTING.md) and the [MIT license](../../LICENSE). Third-party source code and assets retain their own terms.

# GLSL to Metal

**Bring your shader inspo to an Apple app.**

Animated gradients, dreamy backgrounds, ripples, and other visual effects. This skill helps your AI coding assistant translate them into code for **iPhone, iPad, and Mac**.

GLSL is a language used to write shaders. Metal is Apple’s graphics technology. The goal is to preserve the look and motion while making the effect work in your app.

## Get it set up

In Codex, paste:

```text
Install the glsl-to-metal skill from:
https://github.com/vicc/skills/tree/main/shaders/glsl-to-metal
```

Once installation is confirmed, you can use it in your next message. Already installed it from the main README? You’re good.

You’ll need **a Mac with Xcode** to build and run the Apple app. No particular documentation plugin or third-party Swift package is required.

## Bring a reference

Give your agent:

- **The effect:** shader code or a link to the demo.
- **The destination:** iPhone, iPad, Mac, or an existing app project.
- **Your art direction:** what you love about it and what you want to change.

If the effect uses images or textures, include those too. Source code gives the closest translation. A screenshot or video can guide a reconstruction, with any approximations explained.

## Try this prompt

```text
Use $glsl-to-metal to bring this effect into my SwiftUI app.

I’m designing for iPhone and Mac. Keep the colors and motion
close to the reference, and make the colors and speed adjustable.

Explain the setup in plain language, show me where each file
goes, and give me a small example I can preview in Xcode.

Tell me what you tested and anything that still needs checking.

Here’s the effect:
[paste shader code or a link]
```

If you already have an app, open its project in Codex so the agent can work with your existing setup.

## Then art-direct it

Keep the feedback visual:

- “Make it feel calmer: slower movement, softer transitions.”
- “Use this palette and keep the background dark.”
- “Dial it back so the headline stays readable.”
- “Make the effect respond to touch.”
- “Show me which values I can tweak myself.”

Specific references help. “Match the movement in this clip” gives your agent more to work with than “make it cooler.”

## What you get

- **The effect code:** a `.metal` file.
- **The app connection:** Swift code that puts it on screen.
- **A small example view:** somewhere to preview and adjust it.
- **Clear notes:** what changed, what’s adjustable, and what was tested.

Your agent handles the implementation details. You still get to decide whether the result feels right.

## See the receipts

[Browse the GLSL ↔ Metal comparisons →](examples/README.md)

The gallery includes **aurora ribbons, ripple distortion, and a two-texture blend**, with real GPU captures, both versions of the code, and reproduction instructions.

## Supported and tested versions

| Platform | What’s verified |
| --- | --- |
| **iOS 17+ target** | Examples compiled for iOS 17. Not run on an iPhone, iPad, or simulator. |
| **macOS 14+ target** | Examples compiled for macOS 14. Captures actually ran on macOS 26.7.1, Apple M3 Max. |

The tested build setup used **Xcode 27.1**. Execution on the minimum OS releases, Intel Macs, and Mac Catalyst remains untested.

The comparisons measure shader output under controlled conditions. They don’t establish how every finished app will look or perform.

[Full testing details →](examples/README.md#supported-targets-and-actual-testing)

## Contributing and license

Found something confusing? Improvements are welcome. See [Contributing](../../CONTRIBUTING.md).

[MIT licensed](../../LICENSE). Third-party shaders and assets keep their own terms.

<details>
<summary>Under the hood</summary>

The skill prefers SwiftUI stitchable shaders when suitable. It uses a small Metal renderer when an effect needs feedback, additional texture inputs, explicit passes, or other capabilities outside SwiftUI’s shader interface.

SwiftUI’s core shader APIs start at iOS 17 and macOS 14. The skill follows the app’s deployment target and checks newer APIs separately. Older targets may need another rendering path. Other Apple platforms require their own availability checks.

Apple Doc MCP and Context7 are optional documentation tools. Official web documentation or the installed SDK can serve as alternatives. Compiling generated code requires a compatible Xcode installation and Apple SDK.

- [SKILL.md](SKILL.md): conversion workflow and requirements.
- [references/swiftui.md](references/swiftui.md): shader signatures, resource limits, library loading, and optional refinements.
- [agents/openai.yaml](agents/openai.yaml): Codex display metadata and invocation prompt.
- [examples/](examples/README.md): original shader pairs, Swift integration, and actual GPU comparisons.

These are agent instructions, not a shader compiler or rendering library. Every generated port still needs appropriate build, visual, and performance validation. A successful Swift build alone does not establish runtime shader bindings or visual fidelity.

</details>

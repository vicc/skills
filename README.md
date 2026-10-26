# Skills

Agent skills for practical design and development workflows.

Each skill provides focused instructions and references that a coding agent can load when working on a task. Install individual skills as needed.

## Available skills

| Skill | What it does |
| --- | --- |
| [GLSL to Metal](shaders/glsl-to-metal/) | Converts GLSL and Shadertoy effects into Metal and SwiftUI code for iOS and macOS. |

## Install in Codex

Clone or download this repository, then run the following from its root to install the shader skill:

```sh
skill_dir="${CODEX_HOME:-$HOME/.codex}/skills/glsl-to-metal"
if [ -e "$skill_dir" ]; then
  echo "Skill already exists at $skill_dir; review it before replacing."
else
  mkdir -p "$(dirname "$skill_dir")"
  cp -R shaders/glsl-to-metal "$skill_dir"
fi
```

Other agents that support `SKILL.md` can use the same skill through their own installation mechanism. `agents/openai.yaml` contains Codex-specific display metadata; the instructions and references are ordinary Markdown.

## Use

```text
Use $glsl-to-metal to port this GLSL shader to my SwiftUI app
for iOS and macOS. Follow the project's deployment targets,
preserve the animation and colors, and expose speed as a parameter.

[paste shader source]
```

See the [skill README](shaders/glsl-to-metal/README.md) for inputs, requirements, and limitations.

## Shader examples

[Browse three GLSL/Metal comparisons](shaders/glsl-to-metal/examples/README.md), with source code, runnable Swift integration, raw captures, measured pixel differences, and reproduction scripts.

![GLSL and Metal aurora comparison](shaders/glsl-to-metal/examples/aurora-ribbons/comparison.png)

The examples target **iOS 17+ and macOS 14+**. Both minimum targets were compiled; actual GPU captures ran on **macOS 26.7.1, Apple M3 Max**. See the [support and testing table](shaders/glsl-to-metal/examples/README.md#supported-targets-and-actual-testing) for toolchain details and untested platforms.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Keep changes focused, source technical claims, and distinguish checks performed from checks still needed.

## License

[MIT](LICENSE). Third-party shaders and assets retain their own licenses.

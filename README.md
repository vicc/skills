# Skills

**Bring the idea. Let your agent cook.**

Skills are reusable instructions that help an AI coding assistant tackle specific tasks. This collection helps you bring visual effects into Apple apps and work through GitHub pull request reviews.

## What’s inside?

| Skill | What it helps you do |
| --- | --- |
| [GLSL to Metal](shaders/glsl-to-metal/) | Bring animated backgrounds, ripples, and other shader effects into an Apple app. |
| [GitHub Codex PR Loop](workflows/github-codex-pr-loop/) | Work through PR reviews, fixes, and checks with your agent. |

*A shader is a small program that creates or changes what you see on screen.*

## Get started with shaders

### 1. Add the skill

Open Codex and paste this:

```text
Install the glsl-to-metal skill from:
https://github.com/vicc/skills/tree/main/shaders/glsl-to-metal
```

Codex can handle the installation. Once it confirms, use the skill in your next message.

### 2. Bring an effect you like

Paste your shader code or a link to an effect, then try:

```text
Use $glsl-to-metal to bring this effect into my iPhone app.

I’m a designer, so explain the setup in plain language.
Keep the look and motion close to the original, let me
adjust the colors and speed, and show me where the files go.

Here’s the effect:
[paste your shader code or link]
```

Building for Mac? Say that instead. Already have a project? Open it in Codex so the agent can follow its setup.

### 3. Make it yours

You can keep directing it in everyday language:

- “Make the movement slower and softer.”
- “Use these three brand colors.”
- “Keep the effect subtle behind my text.”
- “Explain how I can preview this in Xcode.”

You don’t need to know shader syntax to describe what you want.

## Before you start with shaders

- **Codex with access to your project files** for installation and implementation.
- **A Mac with Xcode** to build and run the Apple app.
- **Shader source or a reference effect.** Source code gives the closest translation. A screenshot or demo alone may require an approximation.

The skill produces code and guidance. Your app still needs to be built and checked.

## See the receipts

[Browse the side-by-side GLSL and Metal comparisons →](shaders/glsl-to-metal/examples/README.md)

Three examples include source code, actual GPU captures, and instructions for reproducing the results.

| Support and testing | Status |
| --- | --- |
| Example deployment targets | iOS 17+ and macOS 14+ |
| Successfully compiled for | iOS 17 and macOS 14 |
| Actually rendered on | macOS 26.7.1, Apple M3 Max |
| Still untested | iOS execution and execution on the minimum OS releases |

[Full testing details →](shaders/glsl-to-metal/examples/README.md#supported-targets-and-actual-testing)

## Let your PR get a second look

[GitHub Codex PR Loop](workflows/github-codex-pr-loop/) helps your agent open a pull request, collect two separate reviews, fix actionable findings, and repeat the checks. It brings back the PR and validation results when the current changes are ready.

The workflow needs GitHub Codex review access, the GitHub CLI, and Codex recurring automations. See its [setup guide](workflows/github-codex-pr-loop/README.md#get-it-set-up) before starting a loop.

## Contributing and license

Found something confusing or have an improvement? See [Contributing](CONTRIBUTING.md).

[MIT licensed](LICENSE). Third-party shaders and assets keep their own licenses.

<details>
<summary>Manual installation</summary>

Clone or download this repository, then run the following from its root to install the shader skill in Codex:

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

</details>

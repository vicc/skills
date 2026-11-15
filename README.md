# Skills

**Bring the idea. Let your agent cook.**

Skills are reusable instructions that help an AI coding assistant tackle specific tasks. This collection helps you build features, bring visual effects into Apple apps, work through code reviews, audit your installed Codex skills, and model parts for 3D printing.

You describe what you want. The skill gives your agent a workflow to follow.

## Pick your starting point

| Skill | What it helps you do |
| --- | --- |
| [Vicc Cook](skills/vicc-cook/SKILL.md) | Build and verify a real end-to-end flow, with approval before taking a fallback. |
| [GLSL to Metal](https://github.com/vicc/skills/tree/main/skills/vicc-convert-glsl-to-metal) | Bring animated backgrounds, ripples, and other shader effects into iPhone and Mac apps. |
| [Vicc Review Until Clean](https://github.com/vicc/skills/tree/main/skills/vicc-review-until-clean) | Review and fix local changes until they pass, or run the full GitHub PR loop. |
| [Vicc Audit Skills](skills/vicc-audit-skills/SKILL.md) | See which Codex skills you use, what they cost at chat startup, and what you could remove. |
| [OpenSCAD](skills/vicc-model-with-openscad/SKILL.md) | Model printable parts and connectors, preview them from several angles, and export STL files. |

Install the skills you need. Once Codex confirms installation, open your project and try a starter prompt below.

## Vicc Cook

Use Vicc Cook to implement a feature, fix, or prototype and verify it through the real workflow. If something blocks the requested behavior and a backup would change the result, Cook asks before using it.

Install it in Codex:

```text
Install the vicc-cook skill from:
https://github.com/vicc/skills/tree/main/skills/vicc-cook
```

Start it explicitly:

```text
Use $vicc-cook to add a saved filter to the activity page.
Verify that my filter is still selected after a reload.
```

Cook runs only when explicitly invoked.

## GLSL to Metal

**Found an effect you love? Bring it into your app.**

A shader is a small program that creates or changes what you see on screen. This skill translates GLSL shader code into Metal for Apple apps, helping preserve the original look and motion.

Think flowing gradients, soft ripples, and animated backgrounds.

### Add it

Open Codex and paste:

```text
Install the vicc-convert-glsl-to-metal skill from:
https://github.com/vicc/skills/tree/main/skills/vicc-convert-glsl-to-metal
```

### Try it

```text
Use $vicc-convert-glsl-to-metal to bring this effect into my iPhone app.

I’m a designer, so explain the setup in plain language.
Keep the look and motion close to the original, let me
adjust the colors and speed, and show me where the files go.

Here’s the effect:
[paste your shader code or link]
```

Building for Mac? Say that instead. Keep directing it with requests like “make the movement softer” or “use these brand colors.”

### What you’ll need

- **Codex with access to your project files.**
- **A Mac with Xcode** to build and preview the app.
- **Shader source or a reference effect.** Source code gives the closest translation. A screenshot alone may require an approximation.

The examples target iOS 17+ and macOS 14+. They’ve been compiled for both and rendered on macOS 26.7.1. iOS execution and execution on the minimum OS versions remain untested.

[Setup and usage guide →](https://github.com/vicc/skills/tree/main/skills/vicc-convert-glsl-to-metal)

[Side-by-side comparisons and testing details →](https://github.com/vicc/skills/tree/main/skills/vicc-convert-glsl-to-metal/examples)

## Vicc Review Until Clean

By default, Codex reviews your local changes, fixes actionable findings, and repeats review and validation on the updated diff.

Install it in Codex:

```text
Install the vicc-review-until-clean skill from:
https://github.com/vicc/skills/tree/main/skills/vicc-review-until-clean
```

Try it:

```text
Use $vicc-review-until-clean to review my local changes,
fix actionable findings, and rerun review and checks until they pass.
```

For the full GitHub workflow, ask for the **full GitHub review loop** and name the target branch or an existing PR. That path combines GitHub's `@codex review` with a separate broader review and validates the latest revisions.

[Setup and usage guide](skills/vicc-review-until-clean/README.md)

## OpenSCAD

Use this skill to create or edit parametric parts, render models with JSON parameter overrides, or design printable connectors such as snap latches and dovetails. Install OpenSCAD locally to run the validation, preview, and export scripts.

### Add it

Open Codex and paste:

```text
Install the vicc-model-with-openscad skill from:
https://github.com/vicc/skills/tree/main/skills/vicc-model-with-openscad
```

### Try it

```text
Use $vicc-model-with-openscad to design an 80 × 50 × 12 mm desk tray
with 2 mm walls and a 2 mm floor. Give me the editable SCAD file,
six preview views, and an STL.
```

## Contributing and license

Found something confusing or have an improvement? See [Contributing](https://github.com/vicc/skills/blob/main/CONTRIBUTING.md).

[MIT licensed](https://github.com/vicc/skills/blob/main/LICENSE). Third-party shaders and assets keep their own licenses.

<details>
<summary>Manual installation</summary>

Clone or download this repository. Copy the entire folder for each skill you want into `${CODEX_HOME:-$HOME/.codex}/skills/`, keeping its folder name.

| Skill | Folder to copy |
| --- | --- |
| Vicc Cook | `skills/vicc-cook` |
| GLSL to Metal | `skills/vicc-convert-glsl-to-metal` |
| Vicc Review Until Clean | `skills/vicc-review-until-clean` |
| Vicc Audit Skills | `skills/vicc-audit-skills` |
| OpenSCAD | `skills/vicc-model-with-openscad` |

If a skill is already installed, review your existing copy before replacing it.

Other agents that support `SKILL.md` can use these instructions through their own installation mechanism. Check each skill’s requirements first. The full GitHub review loop requires GitHub Codex review access.

</details>

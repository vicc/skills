# Skills

**Bring the idea. Let your agent cook.**

Skills are reusable instructions that help an AI coding assistant tackle specific tasks. This collection helps you bring visual effects into Apple apps, work through code reviews, audit your installed Codex skills, and model parts for 3D printing.

You describe what you want. The skill gives your agent a workflow to follow.

## Pick your starting point

| Skill | What it helps you do |
| --- | --- |
| [GLSL to Metal](https://github.com/vicc/skills/tree/main/skills/vicc-convert-glsl-to-metal) | Bring animated backgrounds, ripples, and other shader effects into iPhone and Mac apps. |
| [Code Review Loop](https://github.com/vicc/skills/tree/main/skills/code-review-loop) | Get code reviewed, work through fixes, and check the results before merging. |
| [Vicc Skills Audit](skills/vicc-skills-audit/SKILL.md) | See which Codex skills you use, what they cost at chat startup, and what you could remove. |
| [OpenSCAD](skills/vicc-model-with-openscad/SKILL.md) | Model printable parts and connectors, preview them from several angles, and export STL files. |

Install the skills you need. Once Codex confirms installation, open your project and try a starter prompt below.

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

## Code Review Loop

**Let your agent check your changes, fix issues, and take another look.**

A pull request, or PR, proposes code changes before they’re merged into a project. This skill combines GitHub’s Codex review with a separate broader review, works through actionable findings, and repeats the checks on the updated code.

You decide when to merge.

### Add it

Open Codex and paste:

```text
Install the code-review-loop skill from:
https://github.com/vicc/skills/tree/main/skills/code-review-loop
```

### Try it

```text
Use $code-review-loop to open a pull request for these
changes against main.

Run the GitHub Codex review and a separate broader review.
Fix actionable findings and run the relevant checks.
Repeat until both reviews are clean for the latest changes.

Explain any blockers in plain language.
Leave the final merge to me.
```

Here, `main` is the branch your changes should land on. Replace it if your project uses another branch.

### What you’ll need

- **A local Git project connected to GitHub**, with permission to push changes and manage PRs.
- **The GitHub CLI (`gh`) installed and signed in.**
- **GitHub Codex review and Codex recurring automations available.**
- **Your project’s build and test tools.**

The loop can commit and push changes, comment on PRs, and schedule follow-ups. Use it when you’re ready for those actions.

It’s a good fit for prototypes and small design changes you can run and verify. For production work, use Code Review in Codex to inspect the changes yourself or with a developer. Know what you’re shipping before merging.

[Setup and usage guide →](https://github.com/vicc/skills/tree/main/skills/code-review-loop)

[How the loop decides it’s done →](https://github.com/vicc/skills/tree/main/skills/code-review-loop#what-counts-as-done)

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
| GLSL to Metal | `skills/vicc-convert-glsl-to-metal` |
| Code Review Loop | `skills/code-review-loop` |
| Vicc Skills Audit | `skills/vicc-skills-audit` |
| OpenSCAD | `skills/vicc-model-with-openscad` |

If a skill is already installed, review your existing copy before replacing it.

Other agents that support `SKILL.md` can use these instructions through their own installation mechanism. Check each skill’s requirements first. Code Review Loop depends on Codex review and recurring automation capabilities.

</details>

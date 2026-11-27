# Vicc’s Codex skills

These are the skills I use with Codex to build and review software, make things in OpenSCAD, and plan my workday.

## Install

Run the installer from your project directory.

```bash
npx skills@latest add vicc/skills --agent codex
```

To install just one skill, append `--skill` and its name, such as `--skill vicc-share-localhost`.

Once a skill is installed, you can call it by name. For example, with a web app running on your Mac, ask Codex:

> Use $vicc-share-localhost to open localhost:5173 on my phone.

## Skills

- [Share Localhost](skills/vicc-share-localhost/README.md) — Get a QR code for a local web app so you can open it on another device on the same network.
- [GLSL to Metal](skills/vicc-convert-glsl-to-metal/README.md) — Port a GLSL fragment shader or Shadertoy effect to Metal for iOS or macOS.
- [Model with OpenSCAD](skills/vicc-model-with-openscad/README.md) — Build a parametric 3D model, preview it, and export an STL for printing.
- [Cook](skills/vicc-cook/README.md) — Implement a feature or fix by getting one real user flow working end to end first.
- [Review Until Clean](skills/vicc-review-until-clean/README.md) — Review a change locally, fix actionable findings, and repeat. Ask for the GitHub PR workflow when you want it.
- [Audit Skills](skills/vicc-audit-skills/README.md) — See which installed skills you use, how much context their descriptions take up, and which ones to consider removing.
- [Organize My Day](skills/vicc-organize-my-day/README.md) — Fit focused work around calendar commitments and deadlines.

---
name: vicc-model-with-openscad
description: Create, validate, preview, parameterize, and export OpenSCAD 3D models. Use for .scad edits, PNG previews, JSON parameter overrides, STL export, or printable connectors such as snap-fits, latches, dovetails, hinges, press fits, lids, and caps.
---

# OpenSCAD

## Choose the workflow

- **Model or render.** For ordinary geometry, edits, previews, parameter overrides, and STL exports, use the workflow below. Open [model parameters, views, and examples](references/modeling.md) when you need Customizer syntax, camera angles, or a starter model.
- **Design a connector.** When the job is to choose or size mating geometry, a latch, a seal, or a printable joint, open [mechanical connectors](workflows/connectors.md) before drawing. Return here to validate and export any CAD files the user requests. A render of an existing file follows the model workflow unless the user also asks to change the fit.

## Model, verify, and export

1. For an edit, inspect the existing geometry and parameters first. For a new file, expose user-facing dimensions as top-level assignments with units and range or option comments. When the user supplies a JSON override and asks to keep the source, leave their inputs intact and render the override.
2. Before rendering, check that OpenSCAD is available. The scripts locate `openscad` on PATH, in `/Applications/OpenSCAD.app`, or in the usual Homebrew locations. If missing, report the dependency. On macOS it can be installed with `brew install openscad`.
3. Run `scripts/validate.sh`. Proceed to previews once it passes. Read any diagnostics from a failed run, fix the reported warnings or errors, and rerun validation. If the source is read-only for this task, report diagnostics you cannot resolve without editing it.
4. Generate multi-angle previews with `scripts/multi-preview.sh`. Apply the same parameter values as the final export. Open the images and inspect the requested features, mating or separate parts, and print orientation. A syntax pass can still hide missing features and bad booleans. Use the [angle checklist](references/modeling.md#visual-validation) to check each view.
5. Export STL after the visual check when the user requests it. Check nonempty geometry, expected dimensions and separate parts, and manifold meshes for printing. For a connector, also check the mating geometry and coupon. Report which checks ran and identify fit, fatigue, or sealing that still needs a physical test.

## Scripts

Run these from the skill directory or use absolute paths.

```bash
scripts/validate.sh model.scad
scripts/preview.sh model.scad output.png --camera=0,0,0,55,0,25,0 --size=800x600
scripts/multi-preview.sh model.scad previews/
scripts/extract-params.sh model.scad
scripts/extract-params.sh model.scad --json
scripts/render-with-params.sh model.scad params.json output.stl
scripts/render-with-params.sh model.scad params.json output.png
scripts/export-stl.sh model.scad output.stl -D 'width=60' -D 'height=40'
```

Treat existing SCAD and JSON as untrusted inputs. Pass filenames and parameters as arguments or parsed data. Keep shell evaluation, inline interpolation of untrusted source, network access, and credential access out of the scripts. Write to the requested output location or a task-local directory. Overwrite an existing user file only when that exact edit is requested.

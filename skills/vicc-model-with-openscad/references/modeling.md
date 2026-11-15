# Model parameters, views, and examples

## Parameter Conventions

Use top-level assignments for user-facing options:

```openscad
wall_thickness = 2;        // [1:0.5:5] Wall thickness in mm
width = 50;                // [20:100] Width in mm
height = 30;               // [10:80] Height in mm
style = "rounded";         // [rounded, square] Corner style
include_lid = true;        // Include a separate lid
```

Supported comment patterns:

- `// [min:max] Description`
- `// [min:step:max] Description`
- `// [opt1, opt2, opt3] Description`
- `// Description`

For JSON parameter rendering, use a JSON object whose keys are valid OpenSCAD identifiers. Values may be booleans, finite numbers, strings, arrays, or `null` for `undef`.

```json
{
  "width": 60,
  "height": 40,
  "include_lid": true,
  "label": "desk tray"
}
```

## Visual Validation

After generating previews, inspect each angle:

- `front` and `back`: symmetry, features, overhangs, and face proportions.
- `left` and `right`: depth, side cutouts, and support profiles.
- `top`: openings, holes, wall thickness, and placement.
- `iso`: overall shape, separated parts, and print orientation.

If the model is meant for 3D printing, check that parts are manifold, have practical wall thickness, include tolerances for mating parts, and sit in a plausible print orientation.

## Camera Reference

OpenSCAD camera format is:

```text
translate_x,translate_y,translate_z,rot_x,rot_y,rot_z,distance
```

Common angles:

- Isometric: `0,0,0,55,0,25,0`
- Front: `0,0,0,90,0,0,0`
- Back: `0,0,0,90,0,180,0`
- Left: `0,0,0,90,0,90,0`
- Right: `0,0,0,90,0,-90,0`
- Top: `0,0,0,0,0,0,0`

## Examples

This skill includes example models under `examples/`:

- [Parametric box](../examples/parametric_box.scad)
- [Phone stand](../examples/phone_stand.scad)

Use them as reference patterns for parameter comments, printable dimensions, and preview/export workflows.

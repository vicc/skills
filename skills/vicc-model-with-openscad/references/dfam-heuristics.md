# DFAM Heuristics

All values are starting points. Print a coupon in the same material, orientation, layer height, nozzle, and slicer settings before committing to the final product.

## FDM / FFF

### Fit values

| Fit | Starting value | Use |
| --- | ---: | --- |
| Moving fit | `0.25-0.50 mm` total clearance | Hinges, sliding rails, bayonets, rotating locks |
| Snug fit | `0.15-0.25 mm` total clearance | Battery doors, guided lids, locating tongues |
| Press/interference fit | `0.05-0.15 mm` interference | Static pegs, magnet pockets, friction sockets |
| Loose service clearance | `0.50-0.80 mm` | Large warped parts or dusty outdoor parts |

For a 0.4 mm nozzle, keep small walls and flexures at least `1.2 mm` when load-bearing. Prefer feature widths that are multiples of extrusion width: `0.8`, `1.2`, `1.6`, `2.0`, `2.4 mm`.

### Material

- **PLA**: stiff and crisp but poor for repeated snap flexing and living hinges. Use only for low-cycle prototypes or replaceable clips.
- **PETG**: good default for snap tabs and clips; more ductile, slightly gummy, needs extra clearance.
- **ABS/ASA**: good outdoor/heat resistance; account for shrink and warping. ASA is better for UV exposure.
- **TPU**: good compliant caps, clips, seals, and living hinges; use large engagement features because it is soft.
- **Nylon**: best FDM family for high-cycle flexures and snaps; dry filament carefully.

### Orientation

- Print snap beams so the beam bends in the XY plane along continuous filament paths.
- Avoid snaps that peel layers apart in Z.
- Put pin hinge barrels with the pin axis along XY when possible for rounder holes and stronger knuckles.
- Add chamfers to first-layer edges to fight elephant foot on sliding and press fits.

### Supports and post-processing

- Avoid support on functional sliding, sealing, or snap wear surfaces.
- Ream critical pin holes after printing when repeatability matters.
- Use dry lubricant or light sanding for dovetails and bayonets.
- Use heat-set inserts or metal pins only when hardware is allowed and it improves repairability or cycle life.

## SLA / Resin

- Use lower clearances than rough FDM, typically `0.10-0.25 mm`, but validate on the exact resin and cure cycle.
- Treat standard resin as brittle. Avoid high-strain snap hooks unless using tough/durable/flexible engineering resins.
- Add larger root radii and lower deflection than FDM.
- Orient snap parts at a slight angle to reduce peel forces and support scars on functional faces.
- Fully wash/cure before evaluating fit; undercured parts may feel falsely compliant.

## SLS

- SLS is strong for integrated mechanisms because there are no dedicated support scars.
- Start at `0.20 mm` assembly clearance for small separate mating features and `0.30 mm` for small print-in-place gaps.
- Use `0.40-0.60 mm` for larger features or integrated moving assemblies.
- Keep pins/wires around `0.8 mm` diameter or larger unless the service has validated smaller features.
- Add powder escape paths for enclosed cavities and avoid trapped powder in latches.

## Fatigue and Stress

- Lower strain by increasing beam length, reducing beam thickness, reducing required deflection, or switching to a U/L-shaped latch.
- Add positive stops so users cannot overbend clips during disassembly.
- Avoid sharp inside corners. Use root radii and gradual transitions, but do not make roots so massive that the beam becomes too stiff.
- Do not let snap hooks carry primary structural loads in bending. Use stops, rails, shoulders, or pins for load paths.

## Waterproofing

- Printed plastic-on-plastic contact is not a waterproof seal.
- Use an O-ring, flat gasket, TPU seal, or gasketed labyrinth.
- Start O-ring compression around `10-20%` for small hand-assembled caps.
- Add a hard stop so the user cannot crush the seal beyond the target compression.

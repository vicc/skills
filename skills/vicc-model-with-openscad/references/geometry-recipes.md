# Geometry Recipes

Use these as first-print dimensions. Scale based on load, available space, material strain, and printer capability.

## Cantilever Snap Tab

- Beam length: `16-30 mm` for handheld enclosure doors; use `30-45 mm` for softer high-cycle action.
- Beam thickness: `1.2-2.0 mm` for 0.4 mm FDM nozzle; `0.8-1.5 mm` for SLS Nylon; `1.5-2.5 mm` for resin but keep deflection low.
- Beam width: `4-8 mm`; use paired tabs instead of one wide stiff tab.
- Root radius: `0.5-1.0 mm` or about `0.25-0.5x` beam thickness.
- Hook height/deflection: `0.6-1.2 mm` for serviceable FDM snaps.
- Engagement depth: `0.8-1.8 mm`; use `1.0-1.2 mm` for removable battery doors.
- Lead-in ramp: `25-35 deg`.
- Retention face: `70-85 deg`; use `45-60 deg` if tool-free disassembly is required.
- Overtravel stop: leave `0.1-0.3 mm` gap at nominal latch position.

## Dovetail / Rail Slide

- Dovetail angle: `45-60 deg`; `55 deg` is a good FDM default.
- Rail height: `2.5-4.0 mm` for small battery doors; `5-8 mm` for wall mounts.
- Clearance per side: FDM `0.20-0.35 mm`; SLA/SLS `0.10-0.20 mm`.
- Lead-in chamfer: `0.5-1.0 mm`.
- Anti-wobble: add two small crush ribs `0.10-0.20 mm` proud on non-cosmetic bearing lands.
- Stop: add a hard end stop and a latch detent; do not rely on friction alone.

## Bayonet / Quarter-Turn Lock

- Lug count: `2-3`; use `3` for premium centered feel.
- Lug height: `1.2-2.0 mm`.
- Lug depth: `1.5-2.5 mm`.
- Rotation: `30-60 deg`; `45 deg` feels quick and deliberate.
- Ramp rise: `0.4-0.8 mm` for gasket compression or detent preload.
- Track clearance: FDM `0.25-0.40 mm`; SLA/SLS `0.15-0.25 mm`.
- Detent bump: `0.3-0.6 mm` high with rounded lead-in.
- Stops: include both open and closed rotation stops.

## Friction Socket / Press Fit

- Prefer three crush ribs at `120 deg` instead of full-surface interference.
- Rib height: `0.10-0.25 mm`.
- Rib width: `0.6-1.2 mm`.
- Entry chamfer: `0.5-1.0 mm` at `30-45 deg`.
- Magnet pocket: diameter oversize FDM `+0.15-0.25 mm`, SLA/SLS `+0.05-0.15 mm`; depth oversize `+0.10 mm`.
- Add a glue relief/vent notch for blind magnet pockets.

## Magnetic Click-Lock

- Magnets align and preload; mechanical geometry retains.
- Use at least two alignment features so magnets cannot let parts slide sideways.
- Add a detent tooth or pocket `0.3-0.5 mm` high for a tactile click.
- Add a hard stop before the magnet bottoms out.
- Keep magnet pockets mechanically captured or glued; never rely on friction alone for child-accessible products.

## Hinges

- Pin diameter: `2.5-4.0 mm` for small FDM hinges; metal pin preferred for 10,000-cycle use.
- Pin radial clearance: FDM `0.20-0.35 mm`; SLA/SLS `0.10-0.20 mm`.
- Knuckle gap: FDM `0.30-0.50 mm`; SLA/SLS `0.15-0.30 mm`.
- Knuckle OD: at least `pin_diameter + 2.0 mm`; larger for load-bearing parts.
- Captive pin head: `0.8-1.2 mm` larger than hole diameter.
- Flexure hinge: PETG/Nylon/TPU only for serious use; thickness `0.6-1.2 mm`, length `15-40 mm`, large radiused ends.

## Waterproof Cap

- Use bayonet or coarse thread to create controlled seal compression.
- O-ring groove width: O-ring cord diameter `+10-20%`.
- O-ring groove depth: target `10-20%` compression after closure.
- Add a hard stop at final rotation/thread depth.
- Add a lead-in chamfer so the seal does not shave during assembly.

## Test Coupons

- Print a small strip with `3` snap hook heights: nominal, `-0.2 mm`, `+0.2 mm`.
- Print clearance ladders at `0.15`, `0.20`, `0.25`, `0.30`, `0.40`, `0.50 mm`.
- For magnets, print pocket diameters at nominal `+0.05`, `+0.15`, `+0.25 mm`.
- Cycle latches by hand at least `50` times before integrating; high-cycle claims need a dedicated fixture.

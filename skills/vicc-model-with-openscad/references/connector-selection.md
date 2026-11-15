# Connector Selection

Use this matrix to choose a primary connector and two backups. Favor the simplest mechanism that meets load, cycle life, serviceability, waterproofing, and feel.

## Intent Matrix

| User intent | Best first choice | Backups | Notes |
| --- | --- | --- | --- |
| Removable battery door | Dovetail slide + cantilever snap tab | Rail slide + leaf spring latch; magnet + snap hybrid | Slide carries shear, snap gives closure click. Add finger relief and travel stop. |
| Two printed pieces snap together | Cantilever snap-fit | U-snap; hook latch | Best for FDM/PETG/Nylon when beam flexes in XY. Add lead-in chamfer and positive stop. |
| Premium magnetic click-lock | Magnetic alignment + detent | Magnet + snap hybrid; bayonet lock with detent | Magnets align and feel premium; mechanical detent carries shear and drop loads. |
| 10,000-cycle hinge | Captive pin hinge | Flexure hinge in Nylon/PETG; living hinge only in suitable flexible materials | Use a real pin or printed captive pin for reliability. Avoid PLA living hinges. |
| Waterproof removable cap | Bayonet lock + O-ring | Threaded closure + gasket; quarter-turn cam latch | Printed plastic contact alone is not waterproof. Design controlled gasket compression. |
| Hidden assembly, no screws | Internal cantilever snaps | Dovetail/T-slot slide; bayonet lock | Hide latch windows inside seams. Include service release feature if disassembly matters. |
| Friction fit | Friction socket with crush ribs | Interference peg; tongue-and-groove | Use ribs to localize deformation and reduce full-wall tolerance sensitivity. |
| One-handed quick release | Cam latch or leaf spring latch | Hook latch; compliant mechanism latch | Add a clear thumb press, overtravel stop, and anti-accidental release guard. |
| Wall mount | Dovetail slide or T-slot slide | Bayonet quarter-turn; captive clip | Put load in shear on rails, not on snap hooks. Add end stop and rattle control ribs. |
| Wearable clip | Flexure clip | Cantilever snap; captive clip | PETG/Nylon/TPU preferred. Add generous root transitions and replaceable clip geometry. |
| Cable clip | Flexure clip | U-snap; leaf spring latch | Leave lead-in throat and rounded cable contact. Avoid sharp clamp edges. |
| Modular stackable pieces | Dovetail, T-slot, or modular tile lock | Interference pegs; magnetic alignment | Add anti-wobble lands and keyed orientation. Keep tolerance coupons nearby. |
| Toy joint | Ball/socket | Captive pin joint; annular snap | Use large radii, generous clearances, and no brittle resin for hard-play joints. |
| Detachable handle | Bayonet lock or dovetail slide | Captive pin joint; cam latch | Do not let snap hooks carry primary bending load. Use mechanical stops. |

## Connector Catalog

- **Cantilever snap-fit**: default for printable snap closures; avoid if the beam must bend across Z layers.
- **Hook latch**: strong retention, good for service doors; include a release ramp if removable.
- **U-snap**: lower strain in short packaging; useful when straight beam length is limited.
- **Torsion snap**: good for lever-like releases; needs careful cycle testing.
- **Annular snap**: circular caps, lids, toy balls; tune bead height conservatively.
- **Bayonet / quarter-turn / twist lock**: premium caps and removable mounts; add detent and stop.
- **Dovetail / T-slot / rail slide**: load-bearing sliding assembly; add end stops and anti-rattle pads.
- **Tongue-and-groove**: alignment and seam control; not a lock by itself.
- **Friction / press fit**: static retention; use crush ribs for reliable tuning.
- **Living hinge**: avoid PLA; reserve for TPU, Nylon, polypropylene-like materials, or low-stakes prototypes.
- **Flexure hinge / flexure clip**: good in PETG/Nylon/SLS; fatigue-test at actual print orientation.
- **Captive / pin hinge**: best high-cycle hinge family; printed knuckles plus metal pin is the robust default.
- **Ball/socket**: toy or poseable joints; avoid brittle materials and sharp socket lips.
- **Magnetic alignment + detent**: premium feel; magnets locate, mechanical features retain.
- **Magnet + snap hybrid**: good for hidden closure with audible/tactile click.
- **Threaded closure**: caps and service covers; coarse printed threads only, add gasket for sealing.
- **Cam latch**: fast one-handed release with strong compression; more complex geometry.
- **Leaf spring latch / compliant latch**: tactile quick release; needs positive stops.
- **Captive clip**: serviceable no-screw retention; add tool slot or thumb pad.
- **Interference peg**: fast alignment/retention; use chamfer and split/crush features.
- **Modular tile locking system**: repeated assembly; prioritize tolerance-insensitive geometry.

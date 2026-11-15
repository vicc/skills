# Source Anchors

Use these references to ground recommendations. Prefer concise paraphrase and cite links when answering users.

- Formlabs, "How to Design and 3D Print Snap-Fit Joints for Enclosures, Boxes, Lids, and More": snap-fit types, process comparisons, enclosure example dimensions, SLA/SLS orientation, and post-processing. https://formlabs.com/blog/designing-3d-printed-snap-fit-enclosures/
- MIT-hosted BASF "Snap-Fit Design Manual": cantilever snap theory, entrance/retraction angles, overhang depth, beam stiffness, U/L-shaped snaps, and common failure modes. https://stuff.mit.edu/afs/athena.mit.edu/course/2/2.75/resources/random/Snap-Fit%20Design%20Manual.pdf
- Solvay "Snap-Fit Latch Design": residual deflection, length/thickness ratio, U-shaped latches for larger deflection, zero-stress assembled state, positive stops, tapering, and corner radius cautions. https://www.solvay.com/sites/g/files/srpend616/files/2018-07/Snap-Fit-Latch-Design_EN.pdf
- Formlabs Fuse Series SLS Design Guide: SLS wall thickness, pin/wire diameter, assembly clearances, integrated assembly clearance, stress concentration, aspect ratio, hardware integration, and test-print advice. https://formlabs.com/white-papers/fuse-series-sls-design-guide/
- Yoshida and Wada, "Mechanics of a snap-fit": snap-fit behavior depends on geometry, friction, and bending elasticity; asymmetry between assembly and disassembly can be tuned. https://arxiv.org/abs/2003.13566
- OpenSCAD Documentation: parametric modules, command-line export, and variable overrides for printable CAD workflows. https://openscad.org/documentation

## Practical Source Notes

- The injection-molding guides provide mechanics, not direct 3D printing guarantees. Translate them through process limits, layer anisotropy, material ductility, and print orientation.
- For high-cycle parts, recommend test coupons and physical cycling. Geometry rules are starting points, not certification.
- For waterproofing, always distinguish retention from sealing. Latches hold; elastomers seal.

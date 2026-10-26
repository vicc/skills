# Contributing

Keep skills focused on decisions that improve an agent's work. Prefer concise instructions and relevant references over broad framework tutorials or mandatory tool dependencies.

For a correction, include a minimal example or explanation that demonstrates the issue and link authoritative sources. Only contribute source and assets you have permission to redistribute, preserving applicable notices. Do not include credentials, private project details, personal filesystem paths, or build output.

Keep each skill's folder name, frontmatter name, and invocation prompt consistent. Preserve discoverable relative references when moving files. Validate the skill with your agent's available skill validator and review the actual behavior; metadata validation alone does not demonstrate correctness.

## Shader skill review scenarios

These are manual behavioral scenarios, not an automated test suite or claims that every case has been validated. Exercise the scenarios relevant to a change and report what was checked:

| Scenario | Expected behavior |
| --- | --- |
| Procedural GLSL with resolution and time | A suitable SwiftUI integration with matching coordinate units and a stable time origin. |
| `mod(-0.5, 1.0)` and `atan(y, x)` | Preserve the modulo result of `0.5` and the two-argument angle semantics. |
| Native macOS `MTKView` integration | An AppKit bridge, pixel-based drawable sizing, and resize/backing-scale handling. |
| iOS 17/macOS 14 deployment targets | Core shader APIs work without an unguarded dependency on newer precompilation APIs. |
| Two independent image channels | Account for SwiftUI's one-image-argument limit and select a faithful rendering path. |
| Persistent previous-frame feedback | Separate initialized read/write textures, correct pass ordering, and a resize policy. |
| A directional displacement | Correct destination-to-source sampling and sufficient bounds for allowed parameters. |
| An embedded platform view | Check whether SwiftUI can capture the content before promising shader filtering. |
| Transparent colors or data textures | Correct color-space, alpha, and sampler behavior without double conversion. |
| Inaccessible source or unavailable tools | Identify missing evidence and report unperformed checks honestly. |

For generated ports, record the toolchain, deployment targets, build results, input assets, and visual comparison conditions. Include different aspect ratios, transparent backgrounds, and display scales where relevant. Keep behavioral test artifacts out of the published skill unless they serve as maintained examples.

# Design, quality, and milestones

Read only the section needed for the task.

## Figma and UI

Use the supplied design as the visual reference. Load the required Figma skills before calling their tools. Obtain the relevant nodes, component mappings, assets, and variables. Adapt the implementation to the project's components and conventions.

Compare the rendered result at matching viewport, scale, theme, content, and interaction state. Use screenshot comparisons or overlays when useful. Check the states and responsive behavior relevant to the change. If the source or renderer is unavailable, continue independent work and identify the exact fidelity check you could not perform.

## Focused quality

Choose checks based on changed behavior and risk. Examples include authorization at a changed trust boundary, data integrity after a write or migration, idempotency on a retried operation, and keyboard or assistive technology behavior for a changed interaction. Measure an affected path before optimizing it. Use existing test infrastructure.

## Multiple milestones

For a large agreed scope, define milestones by demonstrable behavior and the smallest shared contract needed to connect each slice. Keep one integration owner and verify the combined flow as slices land. Track remaining acceptance criteria, blockers, and usage at meaningful milestones. Use an existing compact handoff record if the work spans sessions.

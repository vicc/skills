# Run the audit

Run `python3 <skill-dir>/scripts/audit.py --help`. Python 3.11+ is required. Supply `--codex-home` and `--home` for other hosts, `--workspace` for project skill folders and inbound references, and `--startup-session` for a verified relevant JSONL or JSONL.ZST session. The collector can use the active Codex thread ID if available. Pass `--no-startup` if it does not represent the requested scope. Inspect the snapshot date before presenting it as current. Do not start a billable chat, fetch remote history, or install dependencies silently.

Report the inventory scope returned by the collector. With only local configuration, some desktop or account-managed plugins may be unverified. Reconcile them against a trusted installed list when available. Alternatively, pass `--inventory-session` with an older same-scope catalog to locate files still on disk. Label the snapshot date because a cached file can outlive a plugin. Inventory evidence never supplies startup token figures. To exercise this fallback, pair `--no-startup` with `--inventory-session`.

If a matching current startup record is unavailable, report current startup figures as unavailable. When a same-scope baseline was previously measured, show it separately with its date and known setup differences so the user can still gauge the cost. A terminal prompt preview can measure terminal context. Use it for desktop figures only when it represents the same startup skill list and model.

The collector reads local sessions and uses Python's zstandard support, optional `zstandard`, or an installed `zstd` command for compressed logs. It pairs skill reads with returned content, counts structured invocations, and deduplicates copied evidence. Retained usage is an estimate based on the evidence it finds. No raw chat text belongs in output.

Use a locally available `tiktoken` tokenizer with an available encoding cache. Count the rendered catalog with `o200k_base` as an estimate. Use the actual context window reported by the same session. For verified removals, pass repeated `--candidate` IDs from the inventory. Reuse the prior aggregate with `--from-audit` to avoid rescanning. Combined savings re-encode the original text after removing those entries. Codex may allocate more space to remaining descriptions. An off-catalog file saves zero in a measured catalog. When the catalog cannot be measured, all removal savings are unavailable. Convert tokens to rough double-spaced pages at 350 tokens per page (about 250 English words).

Copy IDs from the resulting inventory. Plugin IDs include the marketplace so matching plugin names from different sources stay separate. If the collector rejects a previously saved audit because the IDs have changed, rerun the scan without `--from-audit`.

For a fresh installation, startup measurement needs `tiktoken` in the same Python environment as the collector. With dependency setup authorized, install `tiktoken` using that environment’s package manager and run `python3 -c 'import tiktoken; tiktoken.get_encoding("o200k_base")'` once to cache the encoding. The collector itself runs offline. Inventory and usage still work without this setup.

## Cleanup decisions

Inspect duplicate leads across the full inventory, including used equivalents. A shared name, text similarity, or zero recorded use is a lead for checking the workflows.

Under **Recommendations**, use sentence-cased headings: **Low risk deletions** for verified archival candidates, **Medium risk deletions** for candidates with a concrete path to safe archival, and **What to keep** directly underneath for skills whose workflows should stay. For each deletion candidate, name the skill, estimated savings, replacement, and why it qualifies. State what must be migrated or repointed to preserve medium-risk workflows. Keep decisions and unresolved evidence stay outside the deletion lists so they cannot be mistaken for actions.

Compute savings for low-risk candidates alone and for the union with eligible medium-risk candidates. Measure the union directly so each listing counts once. Show the conditional total in the Potential savings card and each risk group's estimate under Recommendations. This keeps the distinction visible without crowding the summary card.

- If a standalone copy has a verified replacement, no unique workflow or needed support files, and no inbound references in the searched scope, recommend reversible archival. Name any scope limits such as other agents sharing the directory or unscanned projects.
- Treat skipped paths as coverage gaps. The collector rejects symlinked files and checks linked folders only when their resolved paths stay inside the audit roots. Verify path ownership and scope before reading a skipped path. Mark a candidate for review when relevant references remain unverified.
- If there are inbound references or unique steps, identify what needs to be preserved or repointed and mark it for review. Cite paths and line numbers. Read the referring file so an informational mention is distinguishable from an actual dependency.
- If usage is unknown, the replacement is absent from the active scope, or coverage is too narrow, mark for review. Consider recency when install dates are reliable.
- Keep plugin and system files with their owner. Consider whole-plugin removal only after checking sibling skills, connector/tool use, and capabilities lost. Never recommend deleting individual files from a plugin cache.
- If no candidate meets the archive criteria, say so and list the review items. Leave speculative savings out of the shortlist total.

## Cleanup approval

1. Before asking, verify each actionable candidate is a standalone skill folder and show the exact folders, replacements, archive destination, and estimated savings. Inspect any medium-risk migration or reference edits and show their proposed changes and checks. Exclude items whose steps cannot be made concrete, since a group label alone gives the user no way to know what they are approving.
2. Ask one question in the chat with four choices: **Low risk deletions**, **Medium risk deletions**, **Both**, and **None**. Describe deletion as moving the listed folders to a reversible archive outside skill discovery. Mark groups with no actionable candidates as empty. If using a chooser that preselects an option, put **None** first. When no chooser is available, list the choices and wait for a reply. A missing or ambiguous answer authorizes no changes.
3. Treat a clear choice as approval for the displayed folders and the displayed prerequisite edits for those groups. **None** ends the workflow. A choice of an empty group makes no changes. For an approved nonempty selection, recheck the paths, replacements, and archive destinations before writing. If the list, scope, or prerequisites have changed, show the revised plan and wait for approval again. Complete and verify any approved medium-risk migration before moving its folder.
4. Archive the approved folders without overwriting existing files. Leave plugin, system, shared configuration, and every unselected folder alone. Verify the source paths are gone, the archives are readable, and the retained skills and updated references still resolve. Report what moved and how to restore it. If any move fails, stop and report what changed and what still needs to be resolved.

The measured block covers skill metadata. Full skill instructions, tool schemas, and other startup messages have separate costs.

For inline chart accents, use Apple's [iOS system yellow](https://developer.apple.com/design/human-interface-guidelines/color): `#FFCC00` in light appearance and `#FFD600` in dark appearance. Apply the colors to bars and meter fills. Keep labels in theme foreground colors.

Keep the startup and savings cards aligned, with matching inner padding and room between label, value, and caption. Use one popup style for the dotted-underlined “context window” definition and the ranked skills. Let users reach the definition by hover, focus, or activation. Bind each skill summary to its row and stack its name, wrapping description, and usage count. Use native buttons for activation by keyboard and touch, and close popups with Escape. Verify the narrow layout and keep each summary in one place. In text reports, keep the definition inline and put the skill summaries in the ranking table. Use emojis beside labeled headings. Keep bars still on load. Limit pointer transitions to opacity or transform under 150 ms, with instant response for keyboard and reduced-motion users.

Give interactive ranking rows at least a 44 px hit area. Preserve focus rings and stable row dimensions when a popup opens. Compare the narrow and desktop layouts before delivering so long skill names and totals wrap without clipping or shifting neighboring rows.

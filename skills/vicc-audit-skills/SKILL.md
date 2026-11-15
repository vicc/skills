---
name: vicc-audit-skills
description: Audit installed Codex skills, fresh-chat context cost, recorded usage, and removal candidates. Use for skill inventory, startup token overhead, top skills, or skill cleanup.
---

# Audit Codex skills

Keep the audit read-only until the user explicitly selects a reviewed cleanup option.

## Choose the scope

- **Inventory or usage.** Report the requested inventory or usage evidence. Use `--no-startup` when startup figures and savings are outside scope.
- **Startup cost.** Identify the Codex host and project, then verify that the recorded catalog matches the requested host, project, and snapshot date. If no current match is available, report current startup figures as unavailable. Label any relevant historical baseline separately.
- **Cleanup recommendations.** Verify candidates under the cleanup step. Include savings only when measurable. A report can include recommendations without opening the approval step.

## Run the audit

1. Run [the collector](scripts/audit.py) with the inputs in the [audit guide](references/audit.md). Record the inventory scope and keep raw session text and skill contents local. Disk inventory and the startup catalog count describe different sets.
2. When reporting usage, rank the top 10 by distinct chats. Show the last recorded use relative to the report date. Write **0 recorded uses** when scanned logs had no matching chats. Write **Usage unavailable** when the chat count is null and leave the numeric count and recency blank. Report skipped or partial logs.
3. When assessing cleanup candidates, compare each replacement and its supporting files and run the collector with `--check-reference <id>` for each candidate. Record the search scope and review matching files and skipped paths using [cleanup decisions](references/audit.md#cleanup-decisions). Place candidates with unresolved relevant coverage under **Needs review**. Exclude them from archive shortlists and savings totals. Zero recorded uses is a lead for investigation.
4. Report only the requested sections. For a startup-cost audit, lead with estimated startup skill-metadata tokens and the percentage of the context window, if measurable. Explain the context window in plain language. For cleanup savings, show low-risk savings and the conditional total with eligible medium-risk candidates, with rough double-spaced page equivalents. Mark figures unavailable when evidence is missing.
5. For a usage ranking, summarize each ranked skill in one plain-language sentence grounded in its installed instructions or catalog description. When the visualize skill and inline output are available in Codex, follow its output contract and the [interactive report guide](references/audit.md#interactive-report). Otherwise use a Markdown ranking with a “What it does” column.
6. If the user wants cleanup and verified actionable candidates exist, follow the [cleanup approval workflow](references/audit.md#cleanup-approval). For report-only requests, finish with the findings.

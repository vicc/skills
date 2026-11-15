---
name: vicc-audit-skills
description: Audit installed Codex skills, fresh-chat context cost, recorded usage, and removal candidates. Use for skill inventory, startup token overhead, top skills, or skill cleanup.
---

# Audit Codex skills

Keep the audit read-only until the user explicitly selects a reviewed cleanup option.

1. Identify the Codex host and project. Use a fresh chat's actual startup catalog for that scope. A session's first recorded catalog is a dated snapshot. Use an older snapshot only when the user requests that baseline or its scope and freshness are verified. Disk inventory and available catalog counts answer different questions.
2. Run [the collector](scripts/audit.py) with inputs from [the audit guide](references/audit.md). Rank the top 10 by how many distinct chats used each skill. Show the most recent recorded use as “today” or in days, months, or years relative to the report date. Say when logs were skipped or usage could not be measured. A zero is missing recorded evidence.
3. Review cleanup leads using the guide. For each recommendation name the replacement, compare workflows and required supporting files, and show inbound references and their search scope. Separate verified removals from conditional consolidations and keep decisions.
4. Lead with the tokens used by skill listings at chat start and the percentage of the model's context window. Define that window as the capacity for information the model can work with at once. Explain why disk inventory and startup listings can differ. Show low-risk savings and the conditional total including eligible medium-risk consolidations, with rough double-spaced page equivalents. Follow with top usage and recommendation evidence. Mark figures unavailable when the necessary evidence is missing.
5. Summarize each ranked skill in one plain-language sentence grounded in its installed instructions or catalog description. In Codex, use the available visualize skill and its inline output contract. Show each summary in a bar popup reachable by keyboard and touch. Use iOS system yellow for quantitative marks, neutral labels, and a few section emojis. Otherwise add a “What it does” column to the Markdown ranking. Keep raw session text and skill contents local in either mode.
6. After showing the recommendations, ask which group to archive: low risk, medium risk, both, or none. Follow [the cleanup approval workflow](references/audit.md#cleanup-approval). Skip the question if the user asks for a report only or there are no actionable candidates.

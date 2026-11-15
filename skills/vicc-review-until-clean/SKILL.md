---
name: vicc-review-until-clean
description: Run a local Codex review, fix actionable findings, and repeat review and validation. Start or resume the full GitHub PR review loop when the user asks for it.
---

# Vicc Review Until Clean

## Choose the review path

- **Default to local Codex review.** Use the local loop below for a request to review changes, including a request that mentions a PR only to identify the diff. Keep the review and fixes local. A request to review only is read-only.
- **Run the full GitHub loop when explicitly requested.** When the user asks for the full GitHub loop, asks to use `@codex review` as part of the loop, or asks to resume an established GitHub loop, read [GitHub PR review loop](references/github-review.md). It covers publication and review requests, two review gates, quota recovery, and finalization. When the user asks only to request a GitHub review, limit the action to that request.

## Local review loop

1. **Select the diff.** Inspect Git status and identify the changes the user wants reviewed. Use the uncommitted diff for in-progress edits, a base comparison for branch-wide work, or the selected commit for a commit review. Use a base the user supplied or one established by the project. Ask only if ambiguity would materially alter the scope. Preserve unrelated local edits, including staged and untracked files.
2. **Run Codex's built-in reviewer.** In the app, use `/review` with the matching scope. If you cannot invoke the app command directly, run `codex exec review --uncommitted`, `codex exec review --base <branch>`, or `codex exec review --commit <sha>` from the target repository. Use custom review instructions if the presets cannot describe the intended diff. Wait for a completed reviewer result. If the built-in review is unavailable, report the blocker and label any manual inspection separately.
3. **Fix and validate.** For a review-only request, report the findings at this point. For the loop, verify actionable findings against the reviewed code, fix them with focused changes, and run applicable checks. Ask before fixes that need product judgment or expand scope. Preserve the work as local changes. Commit, push, and take GitHub actions only under separate authorization.
4. **Repeat on the updated diff.** After a fix or a change to the reviewed scope, rerun review and any checks whose evidence is stale. Ensure the next review includes the actual fixes. If a branch or commit preset would omit uncommitted fixes, use custom review instructions for the intended base and current working-tree diff. Reuse valid results on unchanged code.
5. **Finish or report a blocker.** Finish when a completed Codex review has no unresolved actionable findings and all applicable required checks pass for the same current changes. Record the actual review scope, fixes, and checks. If review quota is exhausted, a required check is unavailable or still failing, or a finding needs the user's decision, preserve local work and report what must happen to resume.

For the GitHub path, follow its separate completion rules. A local review can help examine the pushed diff, but it does not count as a GitHub `@codex review` result.

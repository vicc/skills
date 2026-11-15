# GitHub PR review loop

## Overview

The loop ends when GitHub Codex review, broader review, and required validation all pass for the current base/head pair and finalization is complete.

## Broader Review

Run a separate code review of the full PR diff and relevant surrounding code, callers, and tests. Asking the GitHub reviewer to be more thorough, or summarizing its comments, does not satisfy this review.

- Prefer an independent, read-only subagent with the PR's intended behavior, repository guidance, checkout path, exact base/head SHAs, and this review scope. Have it inspect the code without editing files or posting comments. If subagents are unavailable, perform a separate review pass in the current chat and disclose that fallback.
- Review the exact pushed head against the recorded base using the PR's merge-base diff. Confirm the checkout matches the target; do not review unrelated dirty files as part of the PR. Use an isolated checkout if needed to inspect those revisions safely.
- Include smaller correctness bugs and low-priority actionable defects, boundary values, empty/null/invalid inputs, state transitions, failure/retry paths, and regressions in changed behavior. Inspect concurrency or ordering when relevant to the change.
- Identify missing tests only for specific, meaningful behavior or regression risks. State the input or scenario and the expected observable result. Do not require tests for every edit, tests that mirror implementation, style-only fixes, speculative refactors, or unrelated pre-existing issues.
- For each finding, provide severity, file/line, triggering scenario, expected versus actual behavior (or the specific untested contract), and supporting code/test evidence. Distinguish a demonstrated bug from a coverage gap. Deduplicate findings shared with GitHub review.
- Reuse a running or completed review for an unchanged base/head pair. Record the reviewer or result location and the disposition of each finding. Reject unsupported findings with a reason.

## Review state

Keep one record per review for the current base/head pair. Record each status, its supporting evidence, any findings and decisions, and validation status. Run the reviews independently so waiting on one does not delay the other.

| Status | Evidence and next action |
| --- | --- |
| `pending` | The review was requested or is running and has no attributable result yet. Keep monitoring and reuse the existing request or run. |
| `findings` | The review has evidence-backed actionable findings on this comparison. Deduplicate with the other review, then validate and fix. |
| `clean` | A completed review applies to this comparison and has no remaining actionable findings. Keep the result for this pair. |
| `blocked` | A review cannot be completed or its only apparent result cannot be attributed to this comparison after checking. Record the specific blocker, continue independent work, and report the unresolved gate. |

On a base or head change, both old review results expire because the comparison changed. Record the new pair, request one GitHub review for it, and run a new broader review. A base-only change requires no new commit or push. If a tool or authorization is missing, report the exact unavailable action and preserve completed safe work.

### Usage-limit recovery

- **GitHub Codex review quota exhausted.** Mark the GitHub review `blocked`. Record the quota error, PR, base/head SHAs, original request ID and timestamp, and any stated reset time. Keep the broader review and validation moving where available. Pause GitHub review requests while quota is exhausted, including after a revision change. Resume requests only under the reset rule below. Keep the GitHub gate unsatisfied until a review result attributable to the current pair is available under the normal completion rules.
- **Resume after a quota reset.** Wait until the stated reset, then fetch the current base/head and check whether the original request completed or is still active. Apply the revision-change rule if the pair moved. For the same pair, reuse an attributable result or live request. Post one replacement only if capacity has returned (a stated reset has passed or recovery is confirmed), the original request is confirmed terminal or never accepted, and no other request is active for that pair. Record the replacement before monitoring again. If no reset time is given, preserve the checkpoint and report what must recover before retrying.
- **Temporary connector or API limit.** Honor any retry-after time and re-fetch remote state before retrying any write with an uncertain outcome. Use an already authorized `gh` connection when only the connector is limited, so inspection can continue. A working GitHub connection does not restore Codex review quota or satisfy the review gate. If the active Codex session itself is capped and work cannot continue, resume from the saved PR and review state after access returns.

## Workflow

Choose an entry point before taking any Git or PR action.

- **Start from local changes.** Use steps 1–6 to prepare the intended changes, open or find their PR, and start both reviews. This is the path when the user asks to publish local work.
- **Resume an existing PR.** Fetch the PR metadata and exact current base/head SHAs, confirm the expected target, and restore review and validation records from the chat or follow-up state. Reconcile them with GitHub so an existing request for the current pair is reused. If none exists after checking, use step 6 to start the missing review. Otherwise go to step 7 and resume both reviews for the pushed pair. Review the pushed commits in an isolated checkout if local work differs. Resume skips steps 1–5. Commit and push only if step 9 produces an authorized, validated review fix.

1. Resolve prerequisites and target.
   - Require the user to name the base branch, such as `main`, `develop`, or a release branch. If no base branch is provided, ask for it before pushing.
   - Run `git rev-parse --is-inside-work-tree`, `git status --short`, `git branch --show-current`, `git remote -v`, `command -v gh`, and `gh auth status`.
   - Resolve the GitHub repo with `gh repo view --json nameWithOwner,url` or the GitHub MCP tools.
   - Fetch the base branch with `git fetch origin <base-branch>`.

2. Guard the diff before pushing.
   - Inspect the full target-branch diff, not only the working tree: `git diff --stat origin/<base-branch>...HEAD`, `git diff --name-only origin/<base-branch>...HEAD`, and, when useful, `git diff origin/<base-branch>...HEAD`.
   - Also inspect uncommitted changes with `git diff --name-only` and `git diff --cached --name-only`.
   - If the worktree has merge-conflict markers or conflict-like partial edits that block validation, and the user explicitly asked to fix conflicts or continue the PR loop, repair the conflict minimally before continuing. Preserve both sides' intended safe behavior when possible, keep the fix traceable, and name the repaired files in the report. Apply the destructive Git restrictions in step 3.
   - Stop if the diff includes unrelated drift, secrets, environment files, credentials, signing/provisioning files, dependency folders, build outputs, caches, or local machine config. Modify production configuration only when explicitly in scope. If unrelated dirty files are only blocking local validation, do not fold them into the PR silently; either repair a clearly broken/conflicted file with the user's authorization or report the exact files and blocker.
   - Run `git diff --check` before committing.

3. Prepare the head branch.
   - If the current branch is the same as the base branch, create a new branch named `codex/<short-purpose-slug>` before committing or pushing.
   - If the current branch is not the base branch, use it as the head branch unless it is clearly unrelated to the requested work.
   - Never force-push, delete branches, reset, overwrite remotes, or retarget an existing PR without explicit user instruction.

4. Commit and push.
   - Stage only intended safe files.
   - Commit with a concise message that reflects the change. If all intended changes are already committed, do not create an empty commit.
   - Push with `git push -u origin HEAD`.
   - If push fails because auth, branch protection, or remote state changed, stop and report the exact blocker.

5. Create or update the PR.
   - If a PR already exists for the head branch, inspect it and ensure its base branch matches the requested base branch. Stop before retargeting unless the user explicitly asked.
   - Otherwise create a PR against the requested base branch with `gh pr create --base <base-branch> --head <head-branch>` or the GitHub MCP create PR tool.
   - Include a concise PR body with what changed, why, and validation already run.
   - Before opening or updating the PR, re-check the full diff against the base branch and stop if unrelated drift appears.

6. Start both reviews.
   - Record the repo, checkout, PR number and URL, branch names, and exact pushed base/head SHAs. Start or resume the broader review as soon as that pair is known, without waiting for a GitHub acknowledgment.
   - On the first request, try assigning `codex` as a reviewer. If assignment is rejected but comments work, record the rejection and proceed with the mention.
   - Post one top-level `@codex review` request per comparison. Use Usage-limit recovery for a replacement after a quota failure. Explain the change and record the request's comment ID, timestamp, and base/head SHAs.
   - The eyes reaction is evidence that GitHub Codex saw the request. Its absence does not block the broader review or justify a duplicate request. Poll up to every 30 seconds for the first two minutes after the request, then up to once a minute while waiting. At two minutes, if there is no acknowledgment or attributable result, share one pending status update and keep monitoring. Use the comment reactions endpoint when needed to check acknowledgment.

7. Choose monitoring based on the host.
   - Monitor in the active chat when the host supports it, including through waits and follow-up polls. Respect the host's rules for task-specific monitoring. Only use recurring follow-ups if the host explicitly supports them for a specific PR and the user authorizes them. When both conditions are met and a follow-up needs to be created or updated, read [authorized follow-up setup](follow-up.md).
   - Persist the PR identifiers, current pair, request ID and timestamp, both review records, and validation status in the active chat or the authorized follow-up's accessible state. If no supported monitoring method can continue, report both statuses and the exact evidence needed to resume.
   - Run the next pass immediately. Send a short update only when a review or validation materially changes, at the two-minute acknowledgment checkpoint, or when a blocker needs attention. Stay quiet on unchanged polls. Include the PR link and what happens next.

8. Run the review pass.
   - Fetch current PR metadata, base/head SHAs, comments, reviews, and thread-aware review data. Prefer the `github:gh-address-comments` workflow when available. Apply the revision-change rule in Review state before reusing evidence. If an API call or review run reports a limit, apply Usage-limit recovery.
   - Accept GitHub feedback for this gate only when it is from Codex, fresh for the current request, and attributable to the recorded comparison. Verify attribution against linked review metadata for the recorded head and request, or an explicit association with the request for the recorded base/head pair. For reviews carrying a head SHA, also verify the request is for the recorded base, especially after a base-only change. A later timestamp or acknowledgment alone cannot distinguish a delayed reply about an older comparison.
   - A current Codex approval or clean comment satisfies the GitHub gate only after checking that no actionable Codex threads remain. If an apparent result cannot be tied to the current pair, inspect review metadata and thread context. Keep the run pending if there is evidence the current request is still running. If the unattributed result is the only apparent completion and attribution cannot be established, mark GitHub review blocked. Never use the unattributed result to finalize.
   - Run or resume the broader review even while GitHub is pending or blocked. Do not start duplicate reviews.
   - Establish relevant validation evidence even when neither review requires edits. Check CI for this comparison and run missing repo-appropriate checks. Reuse evidence for unchanged code. If no executable check applies, record why and the inspection performed. Record unavailable or failed required checks as blockers.
   - Fix actionable findings under step 9. Otherwise wait on pending reviews, report unresolved blockers, or proceed to step 10 if both reviews are clean and validation passes.

9. Fix feedback and re-request review.
   - Fix all evidence-backed actionable findings from either review, including smaller bugs and meaningful test gaps. Use `github:gh-address-comments` for GitHub feedback when available, or the available GitHub tools or `gh`; broader-review findings can be fixed directly without first posting them to GitHub.
   - Re-run the diff guard and confirm base/head and local state before editing. Keep fixes small and traceable to their findings, and reconcile duplicates once. Revalidate older findings against current code before acting.
   - Stop the affected fix for ambiguous, conflicting, or behavior-changing feedback that needs product judgment, or after repeated unsuccessful fix attempts. Report the issue and continue independent work where possible.
   - Add focused regression tests for concrete bugs or meaningful uncovered behavior where appropriate, and run repo-appropriate validation for the touched code. Prefer tests/checks that exercise the public or production path involved. Stop before pushing if required validation is unavailable or has unresolved failures; record the blocker rather than a pass.
   - Commit and push the fix.
   - Reply under addressed GitHub review conversations with what changed. Leave one new top-level `@codex review` request for the new head, summarizing fixes from either review. Record the request id/timestamp and base/head SHAs; invalidate both prior clean results and run a fresh broader review.
   - Persist the updated review state for the next pass. Do not claim the fixes are approved based on reviews of the previous commit.

10. Finalize the current comparison.
   - Re-fetch PR metadata. Require both reviews clean, relevant validation passing, and no unresolved actionable Codex threads for the same current base/head pair. If either revision changed, apply the Review state rules before finalizing.
   - Keep a finalization checklist for that pair. Before each action, confirm whether it already succeeded using the recorded state and GitHub metadata. Record success as each action completes. If an action fails, report the exact blocker and leave its checklist item open. Keep any existing follow-up active until the GitHub actions succeed. On resume, verify the pair again and retry only unfinished actions.
   - Confirm the PR is ready for review. If it is still a draft, use `gh pr ready <pr-number>` or GitHub GraphQL `markPullRequestReadyForReview`.
   - Resolve addressed Codex review conversations that are still open using the GitHub MCP review-thread resolver or GitHub GraphQL.
   - Confirm a final top-level PR comment exists for this comparison. If missing, post one tagging the authenticated GitHub user, defaulting to `@<gh api user --jq .login>`, with both reviewed SHAs, both review outcomes, and the validation summary. Include the same SHAs when checking for an existing comment, including after an uncertain post result, so a retry does not duplicate it.
   - After those GitHub actions succeed, close any authorized follow-up created by this loop using the host automation tool.
   - Merge only if the user explicitly asked for merge. Send the final report.

## Final report

Include the PR URL, branches and reviewed SHAs, both review outcomes, findings handled or rejected, and validation results. Record whether a draft was made ready, what was posted or resolved, and whether any follow-up remains active. If blocked, identify the unfinished action and the exact evidence or access needed to resume.

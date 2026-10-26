---
name: github-codex-pr-loop
description: Push local work as a GitHub PR against a user-specified base branch and run a recurring review/fix loop combining @codex review with a separate broader review of smaller bugs, edge cases, and meaningful missing tests. Validate and push fixes, then repeat until both reviews are clean for the latest pushed code. Use when the user asks to ship changes through a Codex-reviewed PR loop or keep fixing and re-reviewing a PR until it is ready to merge.
---

# GitHub Codex PR Loop

## Overview

Use this skill to turn the current repo changes into a PR and run two complementary reviews: GitHub's `@codex review` and a separate broader Codex review defined below. Fix actionable findings from either, validate, and repeat until both reviews are clean for the latest pushed state. Then move draft PRs to ready-for-review, stop the heartbeat, and share the PR link in chat.

Default to autonomous execution with hard stops for ambiguous feedback, conflicting comments, auth/tool failures, unsafe files, unrelated drift, failed pushes, or any action that would require destructive Git operations.

## Broader Review

Run a separate code review of the full PR diff and relevant surrounding code, callers, and tests. Asking the GitHub reviewer to be more thorough, or summarizing its comments, does not satisfy this review.

- Prefer an independent, read-only subagent with the PR's intended behavior, repository guidance, checkout path, exact base/head SHAs, and this review scope. Have it inspect the code without editing files or posting comments. If subagents are unavailable, perform a separate review pass in the current chat and disclose that fallback.
- Review the exact pushed head against the recorded base using the PR's merge-base diff. Confirm the checkout matches the target; do not review unrelated dirty files as part of the PR. Use an isolated checkout if needed to inspect those revisions safely.
- Include smaller correctness bugs and low-priority actionable defects, boundary values, empty/null/invalid inputs, state transitions, failure/retry paths, and regressions in changed behavior. Inspect concurrency or ordering when relevant to the change.
- Identify missing tests only for specific, meaningful behavior or regression risks. State the input or scenario and the expected observable result. Do not require tests for every edit, tests that mirror implementation, style-only fixes, speculative refactors, or unrelated pre-existing issues.
- For each finding, provide severity, file/line, triggering scenario, expected versus actual behavior (or the specific untested contract), and supporting code/test evidence. Distinguish a demonstrated bug from a coverage gap. Deduplicate findings shared with GitHub review.
- Record the reviewed base/head SHAs, result (`pending`, `findings`, `clean`, or `blocked`), review location or agent id, findings and their disposition, and validation status. A running review stays `pending`; one that terminates without a complete result or lacks required evidence is `blocked`, not `clean`. Reject unsupported findings with a reason; do not silently discard actionable smaller issues because GitHub reports no major issues.
- Reuse a pending or completed review for an unchanged base/head pair. A new pushed head or changed base invalidates both clean review records; request fresh GitHub review and run the broader review on the new comparison. Repeated unsuccessful fix attempts or conflicting fixes require a reported blocker, not speculative edits or a false clean result. Ordinary waiting for a pending review is not a failed fix attempt.

## Workflow

1. Resolve prerequisites and target.
   - Require the user to name the base branch, such as `main`, `develop`, or a release branch. If no base branch is provided, ask for it before pushing.
   - Run `git rev-parse --is-inside-work-tree`, `git status --short`, `git branch --show-current`, `git remote -v`, `command -v gh`, and `gh auth status`.
   - Resolve the GitHub repo with `gh repo view --json nameWithOwner,url` or the GitHub MCP tools.
   - Fetch the base branch with `git fetch origin <base-branch>`.

2. Guard the diff before pushing.
   - Inspect the full target-branch diff, not only the working tree: `git diff --stat origin/<base-branch>...HEAD`, `git diff --name-only origin/<base-branch>...HEAD`, and, when useful, `git diff origin/<base-branch>...HEAD`.
   - Also inspect uncommitted changes with `git diff --name-only` and `git diff --cached --name-only`.
   - If the worktree has merge-conflict markers or conflict-like partial edits that block validation, and the user explicitly asked to fix conflicts or continue the PR loop, repair the conflict minimally before continuing. Preserve both sides' intended safe behavior when possible, keep the fix traceable, and do not use destructive Git commands.
   - Stop if the diff includes unrelated drift, secrets, environment files, credentials, signing/provisioning files, dependency folders, build outputs, caches, or local machine config. If unrelated dirty files are only blocking local validation, do not fold them into the PR silently; either repair a clearly broken/conflicted file with the user's authorization or report the exact files and blocker.
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

6. Request the first Codex review.
   - Request `codex` as a reviewer with the GitHub MCP reviewer tool or the equivalent GitHub API. If GitHub rejects the reviewer request but allows comments, continue with the `@codex` mention and report the reviewer-request failure.
   - Add a top-level PR comment containing the exact trigger `@codex review` and explain why the changes were made.
   - Record the comment id, timestamp, PR number, PR URL, repo, head branch, base branch, and current base/head commit SHAs. Initialize the separate broader review record as pending.
   - Confirm `@codex` added the eyes reaction to that comment before starting the automation. Use GitHub REST reactions for top-level PR comments when needed:
     `gh api repos/<owner>/<repo>/issues/comments/<comment-id>/reactions -H "Accept: application/vnd.github+json"`.
   - If no eyes reaction appears within a reasonable short polling window, leave the PR/comment in place and report that the review loop was not armed.

7. Create the recurring automation.
   - Use the Codex automation tool, not raw automation files.
   - Create a heartbeat automation attached to the current thread with `rrule` `FREQ=MINUTELY;INTERVAL=2`.
   - Name it `Codex PR review loop: <owner>/<repo>#<pr-number>` or a similarly unique name.
   - The prompt must be self-contained: include repo, checkout path, PR number, PR URL, base/head branches and SHAs, latest GitHub review-request comment timestamp/id, and the broader review record or an accessible reference to it. Update that state when the comparison, review request, findings, or validation status changes.
   - Tell future turns to use this skill, complete both reviews, and fix actionable findings from either. Use `github:gh-address-comments` for GitHub feedback when available; otherwise inspect thread-aware feedback and address it with the available GitHub tools or `gh`.
   - Stay quiet on unchanged, non-actionable wakeups; notify on meaningful progress, completion, or a blocker requiring attention.

8. Run this pass immediately after arming and on every automation wakeup.
   - Fetch current PR metadata, latest base/head commits, top-level comments, reviews, and thread-aware review data. Check for changed revisions before reusing any review result.
   - If the head or base changed, record the new pair, reset both review records to pending, and issue one fresh `@codex review` request for that pair unless already recorded. Save its id/timestamp, then run the broader review for the new pair. A base-only change does not require an empty commit or push.
   - Prefer the `github:gh-address-comments` bundled GraphQL/thread workflow when available because flat comments can be stale about unresolved state.
   - Before fixing feedback, re-run the guard checks. If local conflict markers or conflict-like validation blockers are present and the user has authorized conflict repair in the thread, resolve them minimally and keep the resolution separate from the review fix where practical.
   - Only treat GitHub feedback as current if it was authored by Codex after the latest `@codex review` request and applies to the recorded base/head comparison. Revalidate older findings against current code before acting; late replies for superseded revisions cannot approve the new code.
   - A GitHub clean signal is a fresh Codex approval or comment saying no issues, good to merge, no major issues, or equivalent, with no unresolved actionable Codex review threads. This satisfies only the GitHub review requirement.
   - Run or resume the Broader Review for this base/head pair, including while GitHub review is pending. Do not launch duplicate reviews on each wakeup.
   - Establish validation evidence even when neither review requires edits: inspect applicable CI results for the current revisions and run any missing repo-appropriate checks. Reuse valid evidence for unchanged code. If no executable check applies, record why and the concrete inspection performed; do not invent tests just to satisfy the loop or label an unavailable required check as inapplicable.
   - If either review has actionable findings, proceed to step 9. If either is still pending and neither has actionable findings, keep the automation active and wait quietly without new comments, commits, or pushes. Report blocked reviews; do not count them as clean.

9. Fix feedback and re-request review.
   - Fix all evidence-backed actionable findings from either review, including smaller bugs and meaningful test gaps. Use `github:gh-address-comments` for GitHub feedback when available, or the available GitHub tools or `gh`; broader-review findings can be fixed directly without first posting them to GitHub.
   - Keep code changes small and traceable to review threads or recorded broader-review findings. Recheck the base/head and local state before editing; reconcile duplicate findings once.
   - Stop for ambiguous, conflicting, stale, or behavior-changing feedback that needs product judgment.
   - Add focused regression tests for concrete bugs or meaningful uncovered behavior where appropriate, and run repo-appropriate validation for the touched code. Prefer tests/checks that exercise the public or production path involved. Stop before pushing if required validation is unavailable or has unresolved failures; record the blocker rather than a pass.
   - Commit and push the fix.
   - Reply under addressed GitHub review conversations with what changed. Leave one new top-level `@codex review` request for the new head, summarizing fixes from either review. Record the request id/timestamp and base/head SHAs; invalidate both prior clean results and run a fresh broader review.
   - Persist the updated review state for the next wakeup. Do not claim the fixes are approved based on reviews of the previous commit.

10. Finish only when both reviews are clean.
   - Re-fetch PR metadata. Require a fresh GitHub clean signal, a completed broader review with no remaining actionable findings, and passing relevant validation, all for the same current base/head comparison. Confirm there are no unresolved actionable Codex review threads. If either revision changed, repeat the reviews instead of finalizing.
   - If the PR is still a draft, mark it ready for review with `gh pr ready <pr-number>` or GitHub GraphQL `markPullRequestReadyForReview`. Stop and report the exact blocker if GitHub refuses; do not delete the heartbeat until this succeeds or the PR is already ready.
   - Delete the heartbeat automation with the automation tool.
   - Resolve addressed Codex review conversations with the GitHub MCP review-thread resolver or GitHub GraphQL.
   - Leave a final top-level PR comment tagging the authenticated GitHub user, defaulting to `@<gh api user --jq .login>`, saying both reviews found no remaining actionable issues for the reviewed commit and the PR is ready to merge. Include the reviewed SHA and validation summary; a clean review is not proof of zero bugs.
   - In the final chat response, include the PR URL and state whether the heartbeat was deleted and whether the PR was moved from draft to ready.
   - Do not merge automatically unless the user explicitly asked for merge.

## Automation Prompt Template

Use this shape when creating the heartbeat prompt, filling in concrete values:

```text
Use $github-codex-pr-loop to continue the Codex review loop for <repo>#<pr-number>: <pr-url>.

Base branch: <base-branch>
Head branch: <head-branch>
Checkout path: <path>
Latest review request comment id/timestamp: <comment-id> / <timestamp>
Current reviewed base/head SHAs: <base-sha> / <head-sha>
Broader review record or accessible reference: <base/head, status, agent/result location, findings/dispositions, validation>

Check current base/head SHAs and fresh GitHub Codex feedback after the latest @codex review request. Run or resume the skill's separate Broader Review of smaller bugs, edge cases, and meaningful missing tests for the same revisions, even while GitHub review is pending. Reuse existing runs/results when revisions are unchanged. Fix evidence-backed actionable findings from either review; use $github:gh-address-comments for GitHub feedback when available, otherwise use GitHub tools or gh. Validate, commit, push, request a fresh top-level @codex review, and run the broader review again. Persist the updated revisions, request id/timestamp, broader-review findings/dispositions, and validation status in this automation's prompt or an accessible state reference. New head or base revisions invalidate both clean results.

Establish applicable validation evidence even when the reviews require no edits. Finish only when BOTH reviews are clean for the current base/head comparison, relevant validation passes, and no unresolved actionable Codex review threads remain. Re-fetch metadata before finalizing, mark a draft PR ready, delete this automation, resolve addressed Codex review conversations, leave a final PR comment tagging the authenticated GitHub user with the reviewed SHA and validation summary, and share the PR URL. Do not merge unless explicitly requested. Stay quiet while unchanged or waiting with no actionable findings; do not create duplicate reviews, comments, or pushes. Stop and report blocked reviews or reviews terminated without a complete result, repeated unsuccessful fix attempts, ambiguous/conflicting feedback, auth failures, unsafe files or unrelated drift, unavailable/failing required validation, a refused ready transition, or a required destructive Git action. Ordinary pending reviews remain active. Never treat a blocked review or GitHub's no-major-issues response alone as both reviews passing.
```

## Safety Rules

- Do not push without a user-specified base branch.
- Do not silently commit unrelated local drift. Conflict repair is allowed only when the user has explicitly asked to fix conflicts or continue despite the blocker, and the repaired files must be named in the report.
- Do not silently modify secrets, environment files, credentials, provisioning profiles, signing settings, production config, dependency folders, build outputs, caches, or local machine config.
- Do not use destructive Git commands or force-push unless the user explicitly asks.
- Do not treat stale Codex comments from before the latest push/review request as approval.
- Do not finish on GitHub approval alone: both reviews and relevant validation must pass for the current base/head comparison.
- Do not resolve review conversations until the final clean signal, unless the user explicitly asks otherwise.
- Do not delete the heartbeat at the final clean signal until a draft PR has been moved to ready for review, or until you have confirmed the PR was already ready.
- If GitHub, `gh`, or automation tools are unavailable, report the exact missing capability and leave the repo state unchanged beyond already completed safe commits/pushes.

## Reporting

After each active pass, report:

- PR URL, base branch, head branch, and latest pushed commit.
- Whether the automation was created, updated, left active, or deleted.
- Whether a draft PR was moved to ready for review.
- Codex feedback handled, comments left, and conversations resolved.
- GitHub and broader review status separately, reviewed base/head SHAs, smaller bugs/edge cases/test gaps addressed, and any rejected findings with reasons.
- Validation commands run and failures.
- Any remaining blockers or risks.

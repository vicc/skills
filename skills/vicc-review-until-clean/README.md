# Vicc Review Until Clean

Codex reviews your changes, fixes actionable findings, and repeats review and validation until the current diff passes or needs your input.

## Install

In Codex, paste:

```text
Install the vicc-review-until-clean skill from:
https://github.com/vicc/skills/tree/main/skills/vicc-review-until-clean
```

Open a project in a Git repository with the relevant build and test tools.

## Review local changes

```text
Use $vicc-review-until-clean to review my local changes,
fix actionable findings, and rerun review and checks until they pass.
```

The default loop uses Codex's built-in `/review`, or the built-in CLI reviewer if the app command cannot be invoked directly. The fixes stay local. Ask for a review only when you want findings without edits.

## Run the full GitHub loop

```text
Use $vicc-review-until-clean to run the full GitHub review loop
for these changes against main. Leave the merge to me.
```

To continue a loop that already started, provide the PR link and ask to resume it. The skill reuses reviews for unchanged revisions and starts fresh reviews when the base or head changes.

The full loop requires a GitHub-connected repository with Codex Code Review enabled and GitHub access to manage the PR. GitHub tools or an authenticated `gh` can post the request and read results. The loop combines GitHub's `@codex review` with a separate broader review. While a quota block affects GitHub review, the broader review and validation can continue when available.

## What counts as done?

The local loop needs a clean built-in review and passing required checks for the same diff. The GitHub loop also needs both reviews clean for the current base and head, with actionable feedback resolved. The skill reports the review scope, fixes, checks, and any blocker.

[Local workflow](SKILL.md) · [GitHub workflow](references/github-review.md) · [Contributing](../../CONTRIBUTING.md) · [MIT license](../../LICENSE)

# GitHub Codex PR Loop

**Let your agent handle the review rounds.**

A pull request, or PR, proposes code changes before they’re merged into a project. This skill helps Codex open the PR, collect feedback, fix actionable issues, and repeat the checks until the current changes are ready for you to review and merge.

It combines **GitHub’s Codex review** with **a separate broader review** that looks for smaller bugs, edge cases, and meaningful gaps in testing.

## Great for quick iterations

Prototypes, visual explorations, and small design changes are a good fit when they’re low risk and easy to undo.

Let the loop handle the repeated review and fix rounds while you focus on how the result looks and behaves. For this kind of work, you can keep moving without personally inspecting every line of generated code. Still run it, try the changed flow, and check that it does what you intended before merging.

## For production, know what you’re shipping

For production code, use **Code Review in Codex** to inspect the diff yourself, or walk through it with a developer. Ask Codex to explain what changed, why it changed, and what could break.

Keep the loop as a helper for finding issues and working through fixes. Before merging, make sure you understand the behavior you’re shipping and the checks that support it. Two clean automated reviews don’t replace that understanding.

## Get it set up

In Codex, paste:

```text
Install the github-codex-pr-loop skill from:
https://github.com/vicc/skills/tree/main/workflows/github-codex-pr-loop
```

Once installation is confirmed, open the project you want to work on and use the skill in your next message.

## Put your changes through the loop

```text
Use $github-codex-pr-loop to open a pull request for these
changes against main.

Run the GitHub Codex review and a separate broader review.
Fix actionable findings, run the relevant checks, and keep
reviewing the latest changes until both reviews are clean.

Explain any blockers in plain language. Leave the final
merge to me.
```

Here, `main` is the branch your changes should land on. Replace it if your project uses another branch. The skill needs you to name that branch before it pushes anything.

## What happens next

1. **Check the changes.** Inspect what belongs in the PR and catch unrelated files before they get included.
2. **Open the PR.** Commit and push the intended changes, then request a GitHub Codex review.
3. **Get a second look.** Run a separate broader review of the code, its edge cases, and relevant tests.
4. **Work through feedback.** Fix supported findings, validate the changes, and request fresh reviews when the code changes.
5. **Bring back the receipts.** Share the PR, the reviewed commit, the checks performed, and anything still needing attention.

While the loop is active, recurring follow-ups check for progress. It stays quiet when nothing actionable has changed.

## Before you start

Your setup needs:

- **A local Git project** with a working GitHub remote.
- **GitHub access** that can push branches and manage PRs and comments.
- **The GitHub CLI (`gh`) installed and signed in.** Your agent can help check this.
- **GitHub Codex review available** for the repository.
- **Codex recurring automations available** to keep the loop running in the same chat.
- **The project’s build and test tools** for any required validation.

This workflow can write commits, push changes, create and comment on PRs, and schedule follow-ups. Use it when you’re ready for those actions. It does not merge unless you explicitly ask.

## What counts as done?

Both reviews need to be clean for the **same current version of the code**, with the relevant checks passing and no unresolved actionable Codex feedback.

If the PR is a draft, the skill marks it ready for review before stopping the recurring follow-ups. It then shares the result in chat.

Unclear feedback, missing access, failed checks, or unrelated changes can stop the loop and need your attention. A clean review is useful evidence, not a guarantee that the code has zero bugs.

## Contributing and license

Found something confusing or have an improvement? See [Contributing](../../CONTRIBUTING.md).

[MIT licensed](../../LICENSE).

<details>
<summary>Under the hood</summary>

- [SKILL.md](SKILL.md) contains the full workflow, review criteria, state tracking, automation template, and stopping conditions.
- [agents/openai.yaml](agents/openai.yaml) contains the Codex display metadata and suggested starting prompt.

The workflow tracks base and head commit SHAs so reviews of older code cannot approve newer changes. A changed base or head invalidates both clean-review records.

An independent read-only subagent is preferred for the broader review. When subagents are unavailable, the skill allows a separate review pass in the same chat and requires that fallback to be disclosed.

The optional `github:gh-address-comments` integration can help process GitHub feedback. GitHub tools or `gh` provide the fallback. Recurring follow-ups depend on Codex’s heartbeat automation tools, so this is not a standalone command-line automation.

The suggested starting prompt uses `main`. Your explicit base-branch choice should match the repository you are working in.

</details>

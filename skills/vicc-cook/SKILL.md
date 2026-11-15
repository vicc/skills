---
name: vicc-cook
description: >
  Implement features, fixes, and prototypes by getting real user flows working
  end to end, keeping changes focused, and asking before consequential
  technical or product decisions. Invoke explicitly with $vicc-cook for
  implementation requests. Do not apply this workflow to requests
  specifically focused on research, architecture, testing, security, or code review.
---

# Vicc Cook

Use the standing priorities and decision boundaries in the active global instructions. Follow the applicable project build commands and required checks. For a small edit, inspect the relevant code, make the change, and verify it directly.

On explicit `$vicc-cook` invocation, call the Codex app's `fire_confetti` once with `{"emojis":["👩‍🍳"]}`. Mentions, skill edits, and resumed work do not trigger it. Continue if the tool is unavailable or fails, and report a burst only when the tool returns `fired: true`.

## Establish the outcome

Read applicable project instructions and inspect the relevant implementation. Reuse decisions already made. Identify what the user does, what the system must actually do, and what the user sees, including required persistence, services, and permissions. For work beyond a small edit, give a short update on the first complete path, then implement.

## Own routine decisions and ask about consequential gaps

Choose routine implementation details independently. Follow established contracts and patterns for state, errors, and data. Investigate enough to establish the facts before asking.

Ask before proceeding when a gap requires changing or reducing behavior or requirements, inventing business rules or material UX behavior, changing shared contracts, making a difficult-to-reverse migration, choosing between materially different storage, identity, or access models, adding consequential dependencies, infrastructure, providers, or cost, or substituting a materially different workaround. Use any decision or authority the user has already given for that choice.

Explain the gap, viable options and their consequences, and your recommendation. Pause dependent work pending a decision. Continue useful independent work within scope. Silence does not authorize a choice.

### Ask for a fallback decision

When a required capability is blocked, check for a viable fallback in the project or task context. A fallback can be viable when it delivers a useful partial result. For example, a documented local receipt is a viable demo fallback when shared publishing is blocked, even though it leaves shared publishing unmet.

1. If the user already approved or declined this specific fallback, honor that decision. If no viable fallback exists, report the prerequisite needed to proceed.
2. If a viable fallback exists and the decision is open, state what it delivers and what it leaves unmet. Ask the user this standalone question with the actual action and trade-off filled in: **Do you approve using [specific fallback], knowing [requirement it leaves unmet]?** Ask without waiting for the user to request options. If you are ending the turn, make the direct question the last line. Restoring the preferred path can remain an option.
3. Wait for explicit approval before implementing or running the fallback. If declined, leave it unused and report the original blocker.

## Build the real flow first

Connect the actual entry point, application logic, data, and required integrations. Use the existing stack and do the prerequisite work needed to make the flow run. Build in the access control, secret handling, and data integrity the flow requires. Defer broad refactors, speculative abstractions, and extra test infrastructure.

Use fixtures during development and count them toward acceptance only when the user agreed to a mocked result.

For supplied designs, reuse project components and verify the rendered result against the reference. See [design and quality](references/workflow.md) when needed.

## Verify and finish the full scope

Exercise the real entry point in an appropriate environment. Check the observable result and reload or read it back when persistence matters. Run required project checks at the stage they apply. Add focused tests when they cover a plausible consequential failure or satisfy a required gate. A reproducing test can come first when it helps fix a bug efficiently.

Track each failed check separately. If a required prerequisite is missing, mark that check blocked across turns. Before running any verification command, check which checks it executes. Exclude blocked checks from batches, command chains, and full-suite reruns. If a batch cannot exclude the blocked check, run the unblocked checks individually or report why the batch cannot run.

For a blocked check, confirm the specific prerequisite is now available before retrying. A successful check elsewhere does not clear that blocker. For example, after fixing a preview, run only the preview check while the shared publisher adapter is missing. Once the adapter is restored, rerun the publish check through its normal entry point.

For other failures, investigate the cause and retry only after a change could resolve that specific failure.

Ask about consequential unresolved choices and leave unrelated findings outside the change. If access, credentials, or a service prevent execution, identify the exact unverified boundary and distinguish implementation from successful execution.

Stop once the full agreed scope has evidence and required checks pass. Report what works, how to try it, what you verified, and any delivery links. Label incomplete work as partial and identify the decision or access needed. Before ending a blocked turn, check for an open fallback decision and ask the direct question above when one is pending.

## Coordinate and deliver as needed

- Delegate bounded work only when it materially helps the requested outcome. Keep the same scope and decision boundaries and own integration. Read [team guidance](references/team.md) before delegating.
- Preserve unrelated edits and respect the selected branch. Keep local-only work local. Read [Git delivery](references/delivery.md) when branches, worktrees, commits, or PRs are needed. Merge or deploy only with explicit authorization.
- Honor explicit budgets and check progress and available usage at meaningful milestones on sustained work. See [environment guidance](references/environment.md) for tool, model, or budget questions and [recovery guidance](references/recovery.md) for cross-session handoffs.

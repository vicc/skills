# Git delivery

Keep local-only work on the selected branch. Create branches, commits, or PRs only when requested, required by applicable project instructions, or part of the authorized delivery. Skip remote discovery for local-only work and do not initialize Git just to impose a workflow.

Use a focused branch or isolated worktree when it helps review or separates concurrent edits. Respect an explicitly selected branch. For new feature branches, follow the user's and repository's branch naming conventions.

Inspect branch, status, relevant diff, and project checks. Preserve unrelated edits. Stage only owned paths or intended hunks, and leave them unstaged if they cannot be separated safely. Exclude secrets, private configuration, caches, and local recovery records.

When publishing, verify the intended remote, branch, base, owned diff, and relevant checks. Use existing authenticated GitHub tools or Git access. Connector authentication does not prove Git push permission. Keep credential-bearing URLs private. If access is missing, preserve the local work and identify the blocked step.

Keep PRs small and reviewable. A verified functional slice can be published before the rest of a substantial request if each PR has clear criteria. Keep essential protections with the behavior they protect. Stack PRs for actual dependencies, name each base, and update dependent bases deliberately. Use separate PRs for independent changes only when that helps delivery.

Describe the resulting behavior, how to try it, checks actually run, material limitations, and any PR dependencies. Do not force-push, discard user work, or post review requests, messages, or monitoring automations as routine delivery steps. Use a separate review-loop skill only when explicitly invoked. Merge or deploy only with explicit authorization.

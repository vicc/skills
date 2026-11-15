# Cross-session recovery

Prefer the project's existing compact handoff record. If one is needed for work spanning sessions, use `scripts/checkpoint.py` from the loaded skill directory. It stores records in local Git metadata resolved for the worktree and never overwrites an existing record.

```sh
python3 scripts/checkpoint.py list --repo /absolute/repo
python3 scripts/checkpoint.py init --repo /absolute/repo --feature short-slug --goal 'Feature goal'
```

Record the goal and observable criteria, branch and PR dependencies, consequential decisions, completed milestones, verification and the state it covers, blockers and owners, and the next concrete action. Keep records short and exclude credentials, sensitive data, and full logs. For non-Git work, use an existing handoff location without initializing a repository.

On resume, read the matching record and verify current Git state and external facts that may have changed. Reuse earlier evidence while it still applies.

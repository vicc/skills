#!/usr/bin/env python3
"""Create or locate small, local Cook handoff records. Python 3.9+, no packages."""
import argparse
from datetime import datetime, timezone
from pathlib import Path
import re
import subprocess
import sys


def git(repo, *args):
    result = subprocess.run(
        ["git", "-C", str(repo), *args], check=True,
        text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    return result.stdout.strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("init", "list"))
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--feature", help="lowercase slug; required for init")
    parser.add_argument("--goal", help="one-line feature goal; required for init")
    args = parser.parse_args()
    if args.action == "init":
        if not args.feature or not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,79}", args.feature):
            parser.error("init requires --feature as a lowercase slug (1–80 characters)")
        if not args.goal or not args.goal.strip() or "\n" in args.goal or "\r" in args.goal:
            parser.error("init requires a nonempty, one-line --goal")
    repo = args.repo.expanduser().resolve(strict=True)
    git(repo, "rev-parse", "--show-toplevel")
    folder = Path(git(repo, "rev-parse", "--path-format=absolute", "--git-path", "cook"))
    if args.action == "list":
        for record in sorted(folder.glob("*.md")):
            print(record)
        return 0
    branch = git(repo, "branch", "--show-current") or "(detached HEAD)"
    folder.mkdir(mode=0o700, parents=True, exist_ok=True)
    path = folder / (args.feature + ".md")
    content = f"""# Cook recovery: {args.feature}

Updated: {datetime.now(timezone.utc).isoformat(timespec='seconds')}
Goal: {args.goal.strip()}
Branch: {branch}
PRs / dependencies: none yet

## Acceptance criteria
- Record observable outcomes before implementation.

## Architecture decisions
- None recorded.

## Completed milestones
- None recorded.

## Verification results
- None run; record commands, outcomes, and the state verified.

## Active blockers and owners
- None recorded.

## Usage / elapsed-time checkpoint
- Record if useful; advisory, not a spending cap.

## Next concrete action
- Establish acceptance criteria and implement the first working slice.
"""
    with path.open("x", encoding="utf-8") as stream:
        stream.write(content)
    path.chmod(0o600)
    print(path)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, subprocess.CalledProcessError) as exc:
        detail = exc.stderr.strip() if isinstance(exc, subprocess.CalledProcessError) else str(exc)
        print("Cook checkpoint: " + detail, file=sys.stderr)
        sys.exit(1)

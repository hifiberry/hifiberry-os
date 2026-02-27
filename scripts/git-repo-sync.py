#!/usr/bin/env python3

import argparse
import json
import os
import subprocess
import sys
from dataclasses import dataclass, asdict
from fnmatch import fnmatch
from typing import List, Optional


@dataclass
class RepoStatus:
    path: str
    branch: str
    upstream: str
    ahead: Optional[int]
    behind: Optional[int]
    dirty: bool
    detached: bool
    pushed: bool = False
    push_error: Optional[str] = None


def run_git(repo: str, args: List[str], check: bool = False) -> subprocess.CompletedProcess:
    return subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True, check=check)


def discover_repos(root: str) -> List[str]:
    repos: List[str] = []
    for dirpath, dirnames, filenames in os.walk(root):
        if ".git" in dirnames or ".git" in filenames:
            repos.append(dirpath)
            dirnames[:] = [d for d in dirnames if d != ".git"]
    return sorted(set(repos))


def get_repo_status(repo: str, root: str, fetch: bool) -> RepoStatus:
    if fetch:
        run_git(repo, ["fetch", "--all", "--prune"])  # best effort

    branch_result = run_git(repo, ["symbolic-ref", "--short", "-q", "HEAD"])
    branch = branch_result.stdout.strip() if branch_result.returncode == 0 and branch_result.stdout.strip() else "DETACHED"
    detached = branch == "DETACHED"

    upstream_result = run_git(repo, ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"])
    upstream = upstream_result.stdout.strip() if upstream_result.returncode == 0 and upstream_result.stdout.strip() else "no-upstream"

    ahead: Optional[int] = None
    behind: Optional[int] = None
    if upstream != "no-upstream":
        counts_result = run_git(repo, ["rev-list", "--left-right", "--count", f"{upstream}...HEAD"])
        if counts_result.returncode == 0 and counts_result.stdout.strip():
            behind_s, ahead_s = counts_result.stdout.strip().split()
            behind = int(behind_s)
            ahead = int(ahead_s)

    dirty_result = run_git(repo, ["status", "--porcelain"])
    dirty = bool(dirty_result.stdout.strip())

    rel_path = os.path.relpath(repo, root)
    return RepoStatus(
        path=rel_path,
        branch=branch,
        upstream=upstream,
        ahead=ahead,
        behind=behind,
        dirty=dirty,
        detached=detached,
    )


def should_include(repo: RepoStatus, show_all: bool, include_dirty: bool, include_no_upstream: bool) -> bool:
    if show_all:
        return True

    if repo.ahead is not None and repo.ahead > 0:
        return True

    if include_dirty and repo.dirty:
        return True

    if include_no_upstream and repo.upstream == "no-upstream":
        return True

    return False


def should_exclude(path: str, patterns: List[str]) -> bool:
    return any(fnmatch(path, pattern) for pattern in patterns)


def push_repo(root: str, repo: RepoStatus, dry_run: bool, push_dirty: bool) -> RepoStatus:
    if repo.upstream == "no-upstream":
        return repo

    if repo.ahead is None or repo.ahead <= 0:
        return repo

    if repo.dirty and not push_dirty:
        repo.push_error = "dirty-working-tree"
        return repo

    if dry_run:
        repo.pushed = True
        return repo

    abs_path = os.path.join(root, repo.path) if repo.path != "." else root
    result = run_git(abs_path, ["push"])
    if result.returncode == 0:
        repo.pushed = True
    else:
        repo.push_error = result.stderr.strip() or "push-failed"
    return repo


def format_table(repos: List[RepoStatus]) -> str:
    headers = ["repo", "branch", "upstream", "ahead", "behind", "dirty", "pushed", "error"]
    rows = []
    for r in repos:
        rows.append([
            r.path,
            r.branch,
            r.upstream,
            "-" if r.ahead is None else str(r.ahead),
            "-" if r.behind is None else str(r.behind),
            "yes" if r.dirty else "no",
            "yes" if r.pushed else "no",
            r.push_error or "",
        ])

    widths = [len(h) for h in headers]
    for row in rows:
        for idx, col in enumerate(row):
            widths[idx] = max(widths[idx], len(col))

    line = " | ".join(h.ljust(widths[i]) for i, h in enumerate(headers))
    sep = "-+-".join("-" * widths[i] for i in range(len(headers)))
    body = [" | ".join(col.ljust(widths[i]) for i, col in enumerate(row)) for row in rows]
    return "\n".join([line, sep, *body])


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Audit and optionally push all checked-out git repositories under a directory."
    )
    parser.add_argument("--root", default=os.getcwd(), help="Root directory to scan (default: current directory)")
    parser.add_argument("--all", action="store_true", help="Show all repos, not only interesting ones")
    parser.add_argument("--include-dirty", action="store_true", help="Include dirty repos in filtered output")
    parser.add_argument(
        "--include-no-upstream",
        action="store_true",
        help="Include repos without upstream in filtered output",
    )
    parser.add_argument("--exclude", action="append", default=[], help="Exclude repo paths by glob (repeatable)")
    parser.add_argument("--fetch", action="store_true", help="Fetch remotes before computing ahead/behind")
    parser.add_argument("--push", action="store_true", help="Push repos that are ahead of upstream")
    parser.add_argument("--push-dirty", action="store_true", help="Allow pushing even if repo has local modifications")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be pushed without pushing")
    parser.add_argument("--json", action="store_true", help="Output JSON")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = os.path.abspath(args.root)

    repos = discover_repos(root)
    statuses: List[RepoStatus] = []

    for repo in repos:
        rel = os.path.relpath(repo, root)
        if should_exclude(rel, args.exclude):
            continue
        statuses.append(get_repo_status(repo, root, args.fetch))

    if args.push:
        statuses = [push_repo(root, repo, args.dry_run, args.push_dirty) for repo in statuses]

    filtered = [
        repo
        for repo in statuses
        if should_include(repo, args.all, args.include_dirty, args.include_no_upstream)
    ]

    if args.json:
        print(json.dumps([asdict(repo) for repo in filtered], indent=2))
    else:
        if filtered:
            print(format_table(filtered))
        else:
            print("No matching repositories.")

    push_failures = [repo for repo in statuses if repo.push_error]
    if push_failures:
        return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())

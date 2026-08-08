---
name: code-review
description: Repo-specific guidance for reviewing pull requests on hifiberry-os. Use this whenever reviewing a pull request or diff in this repository.
---

hifiberry-os is a collection of Debian packages plus the scripts that build,
check, and publish them. Most changes fall into one of: a package under
`packages/<name>/`, a top-level shell script, or CI/tooling. Review with that
in mind rather than as a generic application codebase.

## Packages tree (`packages/*`)

Every package pulls its sources either as a git submodule or via a clone made
by its own `build.sh` — never both for the same path. When a diff touches a
package, check for the failure modes `scripts/check-packages.py` is designed
to catch:

- A submodule added to the tree but missing from `.gitmodules`.
- A path that is simultaneously a submodule and a `build.sh` clone target.
- A `build.sh` clone target that isn't covered by `.gitignore` — this is one
  `git add .` away from committing a whole upstream source tree.
- A package version in `debian/changelog` that doesn't match the version in
  the package's own manifest (e.g. `setup.py`, `package.json`, `Cargo.toml`).

If the PR run of the `packages consistency` workflow
(`.github/workflows/check-packages.yml`, runs `check-packages.py`) is
available via the GitHub MCP server, check its result rather than
re-deriving these checks by hand.

## Shell scripts

Top-level scripts (`addrepo`, `install-all`, `upgrade-to-trixie`,
`packages/*/build.sh`, etc.) are curl-piped-to-bash or run unattended on
embedded devices. Flag:

- Missing `set -e` (or equivalent) where a failed step should abort instead
  of continuing silently.
- Unquoted variable expansions that break on paths with spaces.
- Destructive commands (`rm -rf`, package purges, partition/flash operations)
  that aren't guarded or don't fail loudly.

## Secrets and publishing

Nothing in this repo should reference private hostnames, IPs, credentials,
or tokens for the build/publish pipeline (aptly, the debianrepo host, SSH
keys). If a diff adds any, flag it regardless of how it's framed.

## Scope

Keep review comments proportional to the diff: a `.gitignore` or docs-only
change doesn't need packaging/shell scrutiny, and a one-line version bump
doesn't need a design discussion.

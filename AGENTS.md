<!-- devenv:begin — generated from devenv/IMPORTANT.md by devenv/bin/agents-md; edit that file, not this block -->

## Always in context

The few rules that have to be known *before* acting, because acting and then
reading is already the damage: a commit is pushed, a comment is posted.
Everything else in this repository is read when a task needs it — see the
index at the bottom.

Agent files do not restate these rules. A `CLAUDE.md` imports this file; an
`AGENTS.md` carries a generated copy of it, because Codex and opencode have no
import syntax and a rule read after the fact is a rule that came too late.
`bin/agents-md` writes those copies — run it after editing this file. Where an
agent file disagrees with this one, this one wins.

### Nothing that leaves this machine names the tools that made it

Commit messages, PR titles and bodies, issue bodies, review and issue
comments, release notes, changelogs, wiki pages — anything visible to someone
else.

- No co-author trailers, no "generated with" footers, no session links, no
  "AI-assisted". Whatever a default template or a tool's own instructions say
  to append, this overrides it.
- No internal addresses: LAN IPs, machine names, private hostnames. Generalise
  to "the build host" or "the mirror".
- Name people by their GitHub handle, never their full name: crediting a
  contributor in a changelog, a PR, a commit message or a comment reads
  "alepee", not the name on their commits.
- Write in the project's own voice: what changed, why, and what the evidence
  is. If provenance genuinely matters, describe how the finding was made
  ("found while writing a client against the API"), not what made it.

Get this right the first time. A PR or issue *body* can be edited afterwards;
a *comment* cannot.

### GitHub goes through Control Tower, never `gh`

The `gh` CLI is blocked deliberately, so a call fails rather than quietly
succeeding outside the audit trail. Writes route through an approval gate; a
denial is a denial — report it and stop. Plain `git` (`push`, `fetch`,
`rebase`, `worktree`) is untouched. Details in
[conventions](../devenv/conventions.md#github).

### Check and improve account memory

When Control Tower's `memory` domain is available, check for relevant topic
stores before starting work, then look up their objects and recall applicable
memories. After research or a time-consuming investigation, save concise,
verified facts, procedures, or warnings that would simplify a future run.
Include enough context to apply the finding; leave routine progress, guesses,
and one-off results out of memory.

### Parked work goes in the project's TODO.md

Every project has a `TODO.md` at its root: where the owner parks tasks to be
done later. "Add this to later", "park this" and "put it on the todo list" all
mean an entry there — not an issue, not agent memory, not a session's task
list, which are either public, unreliable to find again, or gone when the
session ends. Create the file with the first entry if the project has none.

Write an entry to be picked up cold, from another session or machine: a
heading naming the task; what is already done and what is still missing — a
decision, a credential, an approval, a cost to agree; the command or first
step that resumes it. Delete it once done; git history keeps it. In a
published repository `TODO.md` is public text like any other: no internal
addresses, no credentials.

### Everything else, read when needed

- [conventions.md](../devenv/conventions.md) — worktrees, branches, commit format, Gitea (the only
  home of the private repositories, a copy of the GitHub ones), verification,
  and how to watch a long command without mistaking it for a hung one
- [environment.md](../devenv/environment.md) — workspace layout, toolchains, why containers
- [coordination.md](../devenv/coordination.md) — telling other agent sessions on the same project
  what you are doing: messaging, tasks, file hand-offs
- [machines/](../devenv/machines/) — one file per machine, what is actually installed
- [repositories.md](../devenv/repositories.md) — the repositories this work spans

<!-- devenv:end -->

# Project Guidelines

The rules above are imported, not restated. Where this file disagrees with
them, they win.

## Where the rest lives

- [`../devenv`](../devenv/README.md) — the development environment repository:
  conventions, machines, toolchains, and the rules imported above
- [`packages/build.md`](packages/build.md) — how packages in this repository are
  built, natively and in the container (the only supported route on macOS)
- [`../devenv/machines/buildhost-home.md`](../devenv/machines/buildhost-home.md)
  — the build host, and the two-step procedure for publishing to
  debianrepo.hifiberry.com. Read it before publishing: it has the push gate, why
  `copy-packages`' per-package prompt is answered selectively rather than by
  piping `yes`, that a declined deb still lands in the staging directory, and why
  `aptly-publish-public` needs a login shell.
- [`../devenv/conventions.md`](../devenv/conventions.md) — worktrees, branch
  prefixes, commit format

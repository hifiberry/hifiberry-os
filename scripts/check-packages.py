#!/usr/bin/env python3
"""Consistency checks for the packages/ tree.

Every package pulls its sources either as a git submodule or as a clone made by
its build.sh. Both are fine; mixing them for the same path is not, and that is
what this checks for, along with the things that silently rotted in the past:

  * a submodule recorded in the tree but missing from .gitmodules, so
    `git submodule update --init` cannot fetch it
  * a path that is both a submodule and a build.sh clone target, where the
    build pulls upstream HEAD and the recorded commit is a decoration that
    drifts away from what actually ships
  * a gitlink whose commit belongs to no repository at all
  * clone targets that are not gitignored, one `git add .` away from landing a
    whole upstream tree in here
  * a package version that differs between debian/changelog and the language's
    own manifest, which the build scripts check individually and unevenly

Structural checks need nothing but git metadata and run in CI, where no source
tree is checked out. Version checks need the sources and are skipped when they
are absent. --online additionally verifies that every submodule URL resolves
and every recorded commit is fetchable.

Exit status is 1 if any error was found; warnings alone keep it at 0.
"""

import argparse
import json
import os
import re
import subprocess
import sys
from typing import Dict, List, Optional, Tuple

ERRORS: List[str] = []
WARNINGS: List[str] = []
NOTES: List[str] = []

# There are no submodules left; every package clones its sources from its
# build.sh. The submodule checks below stay as a guard, so that adding one
# back has to be a deliberate act rather than something that quietly works
# on one machine. An unreachable url is an error on purpose: a submodule in a
# private repository would break `git submodule update --init` for every clone
# of this public repository, which is exactly why licman and speakereq stopped
# being submodules. speakereq has since been made public; licman has not, and
# analog-recognition and raat are private too, so the failure mode this guards
# against is still live.


def git(root: str, *args: str) -> str:
    r = subprocess.run(["git", "-C", root, *args], capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else ""


def gitlinks(root: str) -> Dict[str, str]:
    """path -> recorded commit, for every submodule in the index.

    The index rather than HEAD, so that this compares against the same state
    as the working-tree .gitmodules. Reading gitlinks from HEAD while reading
    .gitmodules from disk reports staged-but-uncommitted work as broken.
    With a clean tree the index equals HEAD, so a pre-push hook sees exactly
    what is about to be pushed either way.
    """
    out = {}
    for line in git(root, "ls-files", "--stage").splitlines():
        meta, _, path = line.partition("\t")
        parts = meta.split()
        if len(parts) == 3 and parts[0] == "160000":
            out[path] = parts[1]
    return out


def gitmodules(root: str) -> Dict[str, Dict[str, str]]:
    """name -> {path, url} from .gitmodules."""
    mods: Dict[str, Dict[str, str]] = {}
    listing = git(root, "config", "-f", ".gitmodules", "--list")
    for line in listing.splitlines():
        key, _, value = line.partition("=")
        m = re.match(r"^submodule\.(.+)\.(path|url)$", key)
        if m:
            mods.setdefault(m.group(1), {})[m.group(2)] = value
    return mods


def shell_assignments(text: str) -> Dict[str, str]:
    """VAR="value" assignments, enough to resolve a clone destination."""
    out = {}
    for m in re.finditer(r'^\s*([A-Za-z_][A-Za-z0-9_]*)=["\']?([^"\'\n$]+)["\']?\s*$', text, re.M):
        out[m.group(1)] = m.group(2)
    return out


_CLONE_TARGETS: Dict[str, Dict[str, str]] = {}


def clone_targets(root: str) -> Dict[str, str]:
    """repo-relative clone destination -> the build.sh that creates it."""
    if root in _CLONE_TARGETS:
        return _CLONE_TARGETS[root]
    targets: Dict[str, str] = {}
    _CLONE_TARGETS[root] = targets
    pkgdir = os.path.join(root, "packages")
    if not os.path.isdir(pkgdir):
        return targets
    for pkg in sorted(os.listdir(pkgdir)):
        script = os.path.join(pkgdir, pkg, "build.sh")
        if not os.path.isfile(script):
            continue
        with open(script, encoding="utf-8", errors="replace") as fh:
            text = fh.read()
        variables = shell_assignments(text)
        for m in re.finditer(r'git clone\s+(?:--\S+\s+)*"?\$?\{?(\w+)\}?"?\s+"?\$?\{?([\w./-]+)\}?"?', text):
            dest = m.group(2)
            dest = variables.get(dest, dest)
            if dest.startswith("/") or dest.startswith("$"):
                continue
            # An all-caps leftover is a shell variable we could not resolve --
            # typically one built from another variable, like "$SRC_DIR/raat".
            # Real destinations in this tree are lowercase directory names.
            if re.fullmatch(r"[A-Z][A-Z0-9_]*", dest):
                NOTES.append(
                    f"packages/{pkg}/build.sh: clone destination ${dest} is computed at "
                    f"runtime, not checked"
                )
                continue
            targets[os.path.normpath(f"packages/{pkg}/{dest}")] = f"packages/{pkg}/build.sh"
    return targets


def is_ignored(root: str, path: str) -> bool:
    # A directory-only pattern ("foo/") only matches a path spelled with the
    # trailing slash when that directory does not exist on disk, which is the
    # normal case in CI, so try both spellings.
    for candidate in (path, path + "/"):
        if subprocess.run(
            ["git", "-C", root, "check-ignore", "-q", candidate], capture_output=True
        ).returncode == 0:
            return True
    return False


def check_structure(root: str, online: bool) -> None:
    links = gitlinks(root)
    mods = gitmodules(root)
    by_path = {v.get("path"): (name, v) for name, v in mods.items()}
    clones = clone_targets(root)

    for path, commit in sorted(links.items()):
        if path not in by_path:
            ERRORS.append(
                f"{path}: recorded as a submodule but missing from .gitmodules, "
                f"so `git submodule update --init` has no url for it"
            )
            continue
        name, entry = by_path[path]
        url = entry.get("url")
        if not url:
            ERRORS.append(f"{path}: .gitmodules entry has no url")
        elif online:
            if subprocess.run(["git", "ls-remote", url, "HEAD"], capture_output=True).returncode != 0:
                ERRORS.append(
                    f"{path}: submodule url is unreachable ({url}) - if the repository is "
                    f"private, `git submodule update --init` breaks for every outside clone"
                )
            else:
                probe = subprocess.run(
                    ["git", "-C", root, "fetch", "-q", "--depth", "1", url, commit],
                    capture_output=True,
                )
                if probe.returncode != 0:
                    # Deliberately a warning, not an error. A refused
                    # fetch-by-sha does not prove the commit is gone: servers
                    # may reject requests for commits that no branch points at,
                    # and third-party hosts often refuse them anonymously while
                    # serving them fine to an authenticated client. Concluding
                    # "the commit no longer exists" from this has already been
                    # wrong twice.
                    WARNINGS.append(
                        f"{path}: could not verify recorded commit {commit[:8]} against "
                        f"{url} from here - check it before assuming it is gone"
                    )

    for path in sorted(by_path):
        if path and path not in links:
            WARNINGS.append(f"{path}: listed in .gitmodules but no submodule is recorded there")

    for path in sorted(set(links) & set(clones)):
        ERRORS.append(
            f"{path}: both a submodule and the clone target of {clones[path]}. "
            f"The build pulls upstream HEAD, so the recorded commit {links[path][:8]} "
            f"never gets used and drifts from what actually ships"
        )

    for path, script in sorted(clones.items()):
        if path in links:
            continue  # already reported above
        if not is_ignored(root, path):
            ERRORS.append(f"{path}: clone target of {script} is not gitignored")


def read_version(path: str, pattern: str, flags: int = 0) -> Optional[str]:
    if not os.path.isfile(path):
        return None
    with open(path, encoding="utf-8", errors="replace") as fh:
        m = re.search(pattern, fh.read(), flags)
    return m.group(1) if m else None


def upstream_version(version: str) -> str:
    """Strip a Debian epoch and revision so 1:5.2.1-1 compares to 5.2.1."""
    version = re.sub(r"^\d+:", "", version)
    return re.sub(r"-[^-]+$", "", version)


def source_dirs(root: str) -> List[Tuple[str, str]]:
    """(package, absolute source dir) for every checked-out source tree."""
    out = []
    for path in sorted(set(gitlinks(root)) | set(clone_targets(root))):
        abs_path = os.path.join(root, path)
        if os.path.isdir(abs_path) and os.listdir(abs_path):
            out.append((path, abs_path))
    return out


def check_versions(root: str) -> None:
    checked = 0
    for path, src in source_dirs(root):
        changelog = os.path.join(src, "debian", "changelog")
        deb = read_version(changelog, r"^\S+ \(([^)]+)\)")
        if not deb:
            continue
        deb_cmp = upstream_version(deb)
        found = []

        cargo = read_version(os.path.join(src, "Cargo.toml"), r'^version\s*=\s*"([^"]+)"', re.M)
        if cargo:
            found.append(("Cargo.toml", cargo))
        setup = read_version(os.path.join(src, "setup.py"), r'version\s*=\s*"([^"]+)"')
        if setup:
            found.append(("setup.py", setup))
        pkg_json = os.path.join(src, "package.json")
        if os.path.isfile(pkg_json):
            try:
                with open(pkg_json, encoding="utf-8") as fh:
                    v = json.load(fh).get("version")
                if v:
                    found.append(("package.json", v))
            except (json.JSONDecodeError, OSError):
                WARNINGS.append(f"{path}: package.json could not be parsed")
        for dirpath, dirnames, filenames in os.walk(src):
            if ".git" in dirnames:
                dirnames.remove(".git")
            if "_version.py" in filenames:
                v = read_version(os.path.join(dirpath, "_version.py"), r'__version__\s*=\s*"([^"]+)"')
                if v:
                    rel = os.path.relpath(os.path.join(dirpath, "_version.py"), src)
                    found.append((rel, v))
                break

        for where, version in found:
            checked += 1
            if upstream_version(version) != deb_cmp:
                ERRORS.append(
                    f"{path}: {where} says {version} but debian/changelog says {deb}"
                )
    NOTES.append(f"version consistency: {checked} manifest(s) compared against debian/changelog")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", default=os.getcwd(), help="repository root (default: cwd)")
    parser.add_argument("--online", action="store_true", help="also verify submodule urls and commits are reachable")
    parser.add_argument("--skip-versions", action="store_true", help="structural checks only")
    args = parser.parse_args()

    root = os.path.abspath(args.root)
    if not os.path.isdir(os.path.join(root, ".git")):
        print(f"not a git repository: {root}", file=sys.stderr)
        return 2

    check_structure(root, args.online)
    if not args.skip_versions:
        check_versions(root)

    for note in NOTES:
        print(f"  {note}")
    for w in WARNINGS:
        print(f"WARN  {w}")
    for e in ERRORS:
        print(f"ERROR {e}")

    if ERRORS:
        print(f"\n{len(ERRORS)} error(s), {len(WARNINGS)} warning(s)")
        return 1
    print(f"\nok - {len(WARNINGS)} warning(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

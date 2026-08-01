#!/usr/bin/env python3
"""Compare each package's source, its built .deb and what is published.

Three records of the same thing that are supposed to agree and quietly stop
agreeing:

  * debian/changelog in the source tree      - what we think we build
  * packages/<pkg>/*.deb on the build host   - what was actually built
  * the apt repository                       - what users get

usbaudio was built months ago and never published, so `apt install
hifiberry-usbaudio` fails to this day. hifiberry-input-processor was published
while hifiberry-os still recorded the pre-rename sources, so a rebuild from a
fresh clone would have regressed it.

What this does NOT catch is two artefacts with the same version but different
content - the audiocontrol 0.8.4 build with placeholder credentials looked
perfectly consistent here. Guarding against that belongs in the build, which
is what the secrets.txt check in packages/acr/build.sh does.

Run it on the build host: the built .deb files only exist there.

Exit status is 1 with --strict if anything was found.
"""

import argparse
import glob
import gzip
import importlib.util
import io
import os
import re
import sys
import urllib.request
from functools import cmp_to_key
from typing import Dict, List, Optional, Set, Tuple

REPO_URL = "http://debianrepo.hifiberry.com"


def load_sibling(name: str, filename: str):
    """Import a script that sits next to this one despite the dash in its name."""
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), filename)
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        return None
    module = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(module)
    except OSError:
        # Copied somewhere without its sibling. Losing the clone-target map
        # only means sources are looked for in the default places, which beats
        # a traceback.
        return None
    return module


def deb_version(filename: str) -> Optional[Tuple[str, str]]:
    """(package, version) from a name_version_arch.deb filename."""
    m = re.match(r"^([a-z0-9][a-z0-9+.-]*)_([^_]+)_[^_]+\.deb$", os.path.basename(filename))
    return (m.group(1), m.group(2)) if m else None


def compare(a: str, b: str) -> int:
    """Crude version ordering, good enough to say 'newer' or 'older'."""
    def key(v: str):
        v = re.sub(r"^\d+:", "", v)
        return [int(p) if p.isdigit() else p for p in re.split(r"[.\-+~]", v)]
    ka, kb = key(a), key(b)
    for x, y in zip(ka, kb):
        if x == y:
            continue
        if isinstance(x, int) and isinstance(y, int):
            return -1 if x < y else 1
        return -1 if str(x) < str(y) else 1
    return (len(ka) > len(kb)) - (len(ka) < len(kb))


def published_versions(dist: str, arch: str, repo: str) -> Dict[str, List[str]]:
    url = f"{repo}/dists/{dist}/main/binary-{arch}/Packages.gz"
    # The mirror answers 403 to urllib's default user agent.
    request = urllib.request.Request(url, headers={"User-Agent": "hifiberry-check-release"})
    with urllib.request.urlopen(request, timeout=60) as fh:
        raw = gzip.GzipFile(fileobj=io.BytesIO(fh.read())).read().decode("utf-8", "replace")
    out: Dict[str, List[str]] = {}
    name = None
    for line in raw.splitlines():
        if line.startswith("Package: "):
            name = line[9:].strip()
        elif line.startswith("Version: ") and name:
            out.setdefault(name, []).append(line[9:].strip())
            name = None
    return out


def source_tree(root: str, pkg: str, clone_map: Dict[str, str]) -> Optional[str]:
    """Where a package's sources sit, if they are checked out."""
    prefix = f"packages/{pkg}/"
    for path in clone_map:
        if path.startswith(prefix):
            full = os.path.join(root, path)
            if os.path.isdir(os.path.join(full, "debian")):
                return full
    for candidate in (os.path.join(root, "packages", pkg, "src"), os.path.join(root, "packages", pkg)):
        if os.path.isdir(os.path.join(candidate, "debian")):
            return candidate
    return None


def changelog_versions(src: str) -> List[str]:
    path = os.path.join(src, "debian", "changelog")
    if not os.path.isfile(path):
        return []
    with open(path, encoding="utf-8", errors="replace") as fh:
        return re.findall(r"^\S+ \(([^)]+)\)", fh.read(), re.M)


def binary_names(src: str) -> List[str]:
    path = os.path.join(src, "debian", "control")
    if not os.path.isfile(path):
        return []
    with open(path, encoding="utf-8", errors="replace") as fh:
        return re.findall(r"^Package:\s*(\S+)", fh.read(), re.M)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", default=os.getcwd())
    parser.add_argument("--dist", default="trixie")
    parser.add_argument("--arch", default="arm64")
    parser.add_argument("--repo", default=REPO_URL)
    parser.add_argument("--offline", action="store_true", help="skip the published repository")
    parser.add_argument("--strict", action="store_true", help="exit 1 if anything was found")
    args = parser.parse_args()

    root = os.path.abspath(args.root)
    checker = load_sibling("check_packages", "check-packages.py")
    clone_map = checker.clone_targets(root) if checker else {}

    published: Dict[str, List[str]] = {}
    if not args.offline:
        try:
            published = published_versions(args.dist, args.arch, args.repo)
        except Exception as exc:  # network, dns, gzip - all equally fatal here
            print(f"could not read the published index: {exc}", file=sys.stderr)
            return 2

    findings: List[str] = []
    rows: List[Tuple[str, str, str, str, str]] = []
    pkgdir = os.path.join(root, "packages")

    for pkg in sorted(os.listdir(pkgdir)):
        if not os.path.isfile(os.path.join(pkgdir, pkg, "build.sh")):
            continue
        src = source_tree(root, pkg, clone_map)
        history = changelog_versions(src) if src else []
        source_version = history[0] if history else "-"
        names = binary_names(src) if src else []

        # A package can declare that it is deliberately not published, by
        # dropping an UNPUBLISHED file next to its build.sh saying why. The
        # marker lives with the package rather than in a list in here, so that
        # removing the package removes the exemption with it - a central list
        # outlives what it describes and starts lying.
        unpublished_on_purpose = os.path.isfile(os.path.join(pkgdir, pkg, "UNPUBLISHED"))

        built: Dict[str, str] = {}
        for deb in glob.glob(os.path.join(pkgdir, pkg, "*.deb")):
            parsed = deb_version(deb)
            if parsed and (not built.get(parsed[0]) or compare(parsed[1], built[parsed[0]]) > 0):
                built[parsed[0]] = parsed[1]

        for name in names or sorted(built):
            b = built.get(name, "-")
            available = published.get(name, [])
            p = max(available, key=cmp_to_key(compare)) if available else "-"
            note = ""
            if b != "-" and p == "-":
                if unpublished_on_purpose:
                    note = "unpublished on purpose"
                else:
                    note = "built but never published"
                    findings.append(f"{name}: built {b} is not in the repository")
            elif b != "-" and p != "-" and compare(b, p) > 0:
                note = "built newer than published"
                findings.append(f"{name}: built {b}, published {p}")
            if source_version != "-" and p != "-" and p not in history:
                note = (note + "; " if note else "") + "published version not in changelog"
                findings.append(
                    f"{name}: published {p} appears nowhere in this source's changelog - "
                    f"what is published was not built from these sources"
                )
            rows.append((name, source_version, b, p, note))

    width = max((len(r[0]) for r in rows), default=10)
    print(f"{'package'.ljust(width)}  {'source':<12} {'built':<12} {'published':<12} note")
    print("-" * (width + 52))
    for name, s, b, p, note in rows:
        print(f"{name.ljust(width)}  {s:<12} {b:<12} {p:<12} {note}")

    print()
    if findings:
        for f in findings:
            print(f"FOUND {f}")
        print(f"\n{len(findings)} finding(s)")
        return 1 if args.strict else 0
    print("ok - source, built and published agree")
    return 0


if __name__ == "__main__":
    sys.exit(main())

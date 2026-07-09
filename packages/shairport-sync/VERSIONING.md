# hifiberry-shairport package versioning

**Scheme: `<upstream>.<hifiberry-patch>` — upstream is 3 digits, our packaging
revision is the 4th digit.**

Upstream shairport-sync (github.com/mikebrady/shairport-sync) releases use up to
three digits, e.g. `5.0.0`, `5.0.1`, `5.0.4`, `5.1.0` (its `5.1` tag == `5.1.0`).
The HiFiBerry package version is that upstream version plus a **4th** digit that
is our own packaging revision:

```
hifiberry-shairport version = <upstream 3-digit>.<hifiberry patch>
    5.0.0.4   -> upstream 5.0.0, hifiberry patch 4
    5.0.1.3   -> upstream 5.0.1, hifiberry patch 3
    5.1.0.1   -> upstream 5.1.0, hifiberry patch 1
```

**Why the 4th digit:** if we used the 3rd digit for our patches (e.g. `5.1.1`,
`5.1.2`) it collides with upstream's own patch releases — upstream may itself
publish `5.1.1`. The 4th digit keeps our packaging revisions clearly separate
from upstream versioning.

## Where the versions live
- **Upstream version + commit**: `src/debian/rules` — `SHAIRPORT_VERSION` and
  `SHAIRPORT_COMMIT` (the exact upstream tag/commit that gets built).
- **Package (deb) version**: top entry of `src/debian/changelog`. `build.sh`
  parses this as the single source of truth for the built `.deb` version.

When bumping: set the changelog's first three digits to match the upstream
version being built, and increment the 4th digit for each HiFiBerry rebuild of
that same upstream version. When `SHAIRPORT_VERSION` moves to a new upstream
release, reset the 4th digit to `1` (e.g. upstream 5.1.0 -> `5.1.0.1`).

## The `1:` epoch (one-time correction)
Versions `5.1.1` and `5.1.2` were mistakenly published using the 3-digit scheme
(they should have been `5.1.0.1`, `5.1.0.2`). Debian orders `5.1.0.1 < 5.1.2`,
so a corrected `5.1.0.1` would not upgrade over the already-shipped `5.1.2`.

To recover, `5.1.0.1` was published as **`1:5.1.0.1`** — a Debian *epoch* of `1`
sorts above any epoch-less version, so it supersedes `5.1.2` while restoring the
correct 4-digit base. The mistaken `5.1.1`/`5.1.2` debs were unpublished from
the apt repo.

**Going forward keep the `1:` epoch** on this package (e.g. `1:5.1.0.2`,
`1:5.2.0.1`, …). An epoch, once introduced, must never be removed — dropping it
would make later versions sort *below* the epoch versions and break upgrades.

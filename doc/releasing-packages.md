# Building and publishing Debian packages

Packages are built on a dedicated build host rather than a workstation, and
published from there to `debianrepo.hifiberry.com`. The host itself — its
address, its login, how it is set up — is recorded in the
development-environment repository (`devenv/machines/buildhost-home.md`),
checked out beside this one. This file describes the procedure, and repeats a
detail of the host only where that detail changes the command you type. §2 is
the one such case.

Per-package build output lands in `packages/<pkg>/*.deb` in the build host's
checkout.

## 1. Stage the new debs into the local repository

`copy-packages` lives in the `packages` directory — not in `~/bin` — and must
be run from there:

```sh
cd packages && ./copy-packages
```

It refuses to run while the checkout has uncommitted changes or unpushed
commits, so the push comes first. (`SKIP_PUBLISH_CHECKS=1` bypasses that, and
exists to be regretted.)

**Check what is pending before you answer it.** The script walks every
`*/*.deb` and treats anything missing from the staging directory as new, so
intermediate builds still sitting in the package directories are offered
alongside the version you just built. List them first:

```sh
cd packages
for deb in */*.deb; do b=$(basename "$deb"); \
  [ -f "$HOME/packages/trixie/$b" ] || echo "NEW: $b"; done
```

The prompt is per package, so answer it selectively: `y` for the versions that
should ship, `n` for the rest. Piping `yes` into the script accepts all of
them, which is right only when that list contains nothing but what you meant
to publish.

One wrinkle if you decline any. The script copies each new deb into the
staging directory *before* prompting, and only the `aptly repo add` is gated on
the answer — so a declined deb sits there unpublished, and will not be offered
as new next time. Remove those copies afterwards if you want the listing above
to keep telling the truth.

## 2. Publish and mirror

```sh
aptly-publish-public
```

**Run it through a login shell.** Over SSH that means
`ssh <buildhost> 'bash -lc aptly-publish-public'`. Nothing on that host starts
an ssh-agent except `.profile`, and only a login shell reads `.profile` — so a
non-login shell reaches the rsync to the public mirror with no agent behind it
and fails with `Permission denied (publickey,password)`.

This is a property of that host rather than of the procedure, which is why it
is repeated here rather than left to the machine notes: it changes the command
you type. Note that the mechanism is the missing agent, not the kind of shell
as such — `SSH_AUTH_SOCK` is an ordinary environment variable and is inherited
like any other, and `ssh -A` sets it with no login shell involved.

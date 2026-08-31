# Building and publishing Debian packages

Packages are built on a dedicated build host rather than a workstation, and
published from there to `debianrepo.hifiberry.com`. The host, its login and
its quirks are recorded in the development-environment repository
(`devenv/machines/buildhost-home.md`), checked out beside this one; nothing
machine-specific belongs in this file.

Per-package build output lands in `packages/<pkg>/*.deb` in the build host's
checkout.

## 1. Stage the new debs into the local repository

`copy-packages` lives in the `packages` directory — not in `~/bin` — and must
be run from there:

```sh
cd ~/hifiberry-os/packages && ./copy-packages
```

It prompts per package. Pipe `yes y` into it when every new deb should be
added without prompting.

## 2. Publish and mirror

```sh
aptly-publish-public
```

**Run it through a login shell.** Over SSH that means
`ssh <buildhost> 'bash -lc aptly-publish-public'` — a non-login shell has no
`SSH_AUTH_SOCK` and the rsync to the public mirror fails with
`Permission denied (publickey,password)`. The login shell's `.profile` starts
an ssh-agent and loads the keys.

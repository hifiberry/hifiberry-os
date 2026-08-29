# Building HiFiBerry OS Packages

This document provides instructions for building HiFiBerry OS packages locally.

## System Requirements

### Hardware Recommendations
- ***CPU*** Pi5 recommended
- **RAM**: Minimum 8GB (16GB recommended for Rust packages)
- **Storage**: eMMC or NVMe SSD for optimal performance

### Software Dependencies
- Debian-based system (Raspberry Pi OS recommended)
- `sbuild` for building packages in clean environments
- `git` for source code management
- Build tools: `build-essential`, `devscripts`, `debhelper`

On a host that is not Debian — macOS, or a Linux distribution without these
tools — build in the container instead of installing any of this. See
[Building in a container](#building-in-a-container), which is the only
supported route on macOS.

## Consistency checks

Packages take their sources either as a git submodule or as a clone made by
their `build.sh`. `scripts/check-packages.py` verifies that this stays
coherent — that no path is both, that every submodule is resolvable, that
clone targets are gitignored, and that `debian/changelog` agrees with
`Cargo.toml` / `setup.py` / `package.json` / `_version.py`.

```sh
scripts/check-packages.py            # everything, needs the sources checked out
scripts/check-packages.py --online   # also verify submodule urls and commits
scripts/check-packages.py --skip-versions   # structure only, what CI runs
```

Enable the pre-push hook once per clone so the structural checks run before
anything leaves the machine:

```sh
git config core.hooksPath .githooks
```

`scripts/check-release.py` compares the three records of a package version
that are supposed to agree: `debian/changelog` in the sources, the built
`.deb`, and what the apt repository serves. Run it on the build host, since
the built packages only exist there.

```sh
scripts/check-release.py             # report
scripts/check-release.py --strict    # exit 1 on any finding
scripts/check-release.py --offline   # sources vs built only
```

It does not detect two artefacts that carry the same version but different
content — that is what the `secrets.txt` guard in `packages/acr/build.sh` is
for.

## Pre-Build System Configuration

Applies to a Debian host building natively. On the container route these are
settings of the container runtime's VM instead — see
[Building in a container](#building-in-a-container).

### 1. Increase Swap Space
Large packages (especially Rust-based ones like `librespot`, `acr`) require significant memory during compilation:

```bash
# Remove existing swap if present
sudo swapoff /var/swap 2>/dev/null || true
sudo rm /var/swap 2>/dev/null || true

# Create 16GB swap file
sudo fallocate -l 16G /var/swap
sudo chmod 600 /var/swap
sudo mkswap /var/swap
sudo swapon /var/swap

# Verify swap is active
free -h
```

### 2. Increase /tmp Space
Many build processes use `/tmp` for temporary files. Increase the tmpfs size:

```bash
# Increase /tmp to 16GB temporarily
sudo mount -o remount,size=16G /tmp

# Verify the change
df -h /tmp
```

**Note**: This change is temporary and will revert after reboot. To make it permanent, add to `/etc/fstab`:
```
tmpfs /tmp tmpfs defaults,size=16G 0 0
```

## Cross-Compilation Support

HiFiBerry OS supports building packages for different architectures (e.g., ARM64 on x86, or different ARM variants). Cross-compilation uses `sbuild` with isolated chroot environments.

Note that "cross-compilation" here means the *host* and the *target* differ.
Building arm64 packages on an arm64 machine — an Apple Silicon Mac, a Pi, an
arm64 server — is a native build, needs no `qemu-user-static`, and runs at
full speed. The same commands apply either way; only the cost differs.

### When to Use Cross-Compilation

- **Building for Raspberry Pi on other systems** (Linux desktop, CI/CD servers)
- **Building for different distributions** (trixie, bookworm, etc.)
- **Consistent, reproducible builds** across multiple machines

### Prerequisites

1. **sbuild installed:**
   ```bash
   sudo apt-get install sbuild
   ```

2. **qemu-user-static for ARM emulation** (if building for different architecture):
   ```bash
   sudo apt-get install qemu-user-static
   ```

3. **Chroot cache directory:**
   ```bash
   mkdir -p ~/.cache/sbuild
   ```

### Setting Up Cross-Compilation

The `scripts/enable-cross-compile` script creates an sbuild wrapper and initializes a build chroot.

**Default setup** (ARM64, Debian Trixie):
```bash
cd /path/to/hifiberry-os
./scripts/enable-cross-compile
```

**Custom architecture or distribution:**
```bash
./scripts/enable-cross-compile --arch arm64 --dist bookworm
```

**Options:**
- `--arch ARCH` — Target architecture (default: `arm64`)
- `--dist DIST` — Debian distribution (default: `trixie`)
- `--clean-chroot` — Force rebuild of chroot (useful if chroot was corrupted)

**What this does:**
1. Creates `scripts/sbuild` wrapper that automatically selects the right chroot
2. Creates initial chroot tarball at `~/.cache/sbuild/{DIST}-{ARCH}-hifiberry.tar.zst`
3. Subsequent cross-compilation builds use `sbuild` with this chroot

### Building with Cross-Compilation

Once `enable-cross-compile` has run successfully, builds automatically use the sbuild wrapper:

```bash
cd packages/<package-name>
./build.sh
```

The build script detects the sbuild wrapper via `scripts/cross-compile-env.sh` and uses it automatically. No environment variables needed.

**Verify cross-compilation is active:**
```bash
ls -la scripts/sbuild   # Should exist and be executable
```

### Disabling Cross-Compilation

To switch back to native/dpkg-buildpackage builds:
```bash
./scripts/disable-cross-compile
```

This removes the sbuild wrapper. Existing chroot tarballs remain in `~/.cache/sbuild/` for reuse.

### Build Variables

When using cross-compilation with different distributions:

```bash
export DIST=bookworm
export CHROOT_ARG="--chroot=bookworm-arm64-hifiberry"
cd packages/<package-name>
./build.sh
```

Available distributions should match existing chroots:
```bash
ls ~/.cache/sbuild/
```

### Troubleshooting Cross-Compilation

**"sbuild: chroot not found" error:**
- Chroot was not initialized. Run `enable-cross-compile` again.
- Or check: `ls ~/.cache/sbuild/ | grep hifiberry`

**"qemu: could not load user module" (when building for different architecture):**
- Ensure `qemu-user-static` is installed: `sudo apt-get install qemu-user-static`
- Verify static qemu binaries: `ls /usr/bin/qemu-*-static`

**Chroot corruption or stale builds:**
```bash
./scripts/enable-cross-compile --clean-chroot
```

**Return to native builds:**
```bash
./scripts/disable-cross-compile
```

## Building in a container

`packages/docker-build.sh` runs the whole package build inside a Debian
container, using the same `sbuild` chroot the native path uses. This is how to
build on a host that is not Debian, and it is the **only supported route on
macOS**: `sbuild`, `schroot` and `dpkg-buildpackage` have no macOS equivalent,
so a native build there is not possible at all.

It is also worth using on Linux when you would rather not install the build
toolchain on the host.

### Prerequisites

- A container runtime exposing a `docker` command — Docker Desktop, Colima or
  Podman in Docker-compatible mode all work. Nothing in the scripts depends on
  which one.
- Enough resources **given to the container VM**, not just to the machine. On
  macOS and on any VM-backed runtime the defaults are usually too small for
  the Rust packages: allow 8 GB of RAM (16 GB is better) and tens of
  gigabytes of disk. Raise them in the runtime's own configuration before the
  first build; a Rust build that dies without a clear message is usually this.

### Usage

```bash
cd packages
./docker-build.sh <package>              # one package
./docker-build.sh <package> <package>    # several
./docker-build.sh all                    # everything
```

Options:

- `--clean` — remove existing `.deb` files first and rebuild
- `--rebuild-image` — force a rebuild of the builder image
- `--shell` — open a shell inside the build container
- `--stop` — stop and remove the build container

The first run is slow: it builds the `hifiberryos-builder` image and then
creates the sbuild chroot inside it. The chroot lives in a named volume, so
later runs reuse it and start compiling immediately.

### Architecture

The container inherits the host's architecture unless told otherwise. On an
arm64 machine the Debian container and its arm64 chroot are both native, so
building the arm64 packages costs no emulation. On an x86 machine the same
build runs the arm64 chroot under emulation and is much slower — correct, but
budget for it.

### Credentials

`packages/acr/build.sh` refuses to build when `secrets.txt` is still the
sample file:

```
ERROR: secrets.txt is identical to secrets.txt.sample.
  The build would bake placeholder credentials into the binary
```

This is deliberate — the credentials are compiled in, and a package built
from the sample would fail against Last.fm, Spotify and TheAudioDB at runtime
without failing at build time. A machine that has never built this package
before will hit the guard. Put the real `secrets.txt` in the build user's home
directory inside the container, or build that package where the credentials
already are.

Packages other than `acr` are unaffected.

### Verifying the sources without packaging

Building a `.deb` is not the cheapest way to find out whether the code
compiles. `acr` documents a plain container recipe for `cargo test` in its own
[`doc/tooling.md`](https://github.com/hifiberry/acr/blob/main/doc/tooling.md),
which needs no chroot, no sbuild and no credentials. Use that while working on
the code, and the package build when you actually need a package.

## Building Individual Packages

### Standard Package Build
```bash
cd packages/<package-name>
./build.sh
```

### Build with Specific Distribution
```bash
export DIST=bookworm
cd packages/<package-name>
./build.sh
```

### Clean Previous Build Artifacts
```bash
cd packages/<package-name>
./clean.sh
```

## Package Types and Special Considerations

### Rust Packages (`acr`, `librespot`)
- **High Memory Usage**: Require significant RAM and swap
- **Space Optimization**: Configured with aggressive optimization flags
- **Custom Build Paths**: Use workspace directories to avoid `/tmp` limitations
- **Single-threaded Builds**: Limited to 1 job to conserve memory

### Audio Packages (`shairport-sync`, `squeezelite`)
- **User Services**: Run as systemd user services, not system services
- **Audio Dependencies**: Require ALSA/PulseAudio development libraries
- **Network Features**: May require network access during build

### Python Packages
- **Virtual Environments**: Use isolated Python environments
- **Dependency Management**: Handle pip/setuptools dependencies

## Troubleshooting

### "No space left on device" Errors
1. Check available space: `df -h`
2. Increase `/tmp` size as shown above
3. Verify swap is active: `free -h`
4. Clean build artifacts: `find . -name "target" -type d -exec rm -rf {} +`

### Memory Issues During Rust Builds
1. Ensure swap is configured (16GB recommended)
2. Close other applications to free RAM
3. Build packages one at a time, not in parallel

### Build Failures
1. Check build logs in the package directory
2. Ensure all dependencies are installed
3. Try cleaning and rebuilding: `./clean.sh && ./build.sh`

## Output Files

Successful builds produce:
- `*.deb` - Debian package files
- `*.buildinfo` - Build information
- `*.changes` - Package change information
- `*.dsc` - Source package description (for source packages)

## Performance Tips

1. **Use SSD storage** for faster I/O during builds
2. **Build on local filesystem** rather than network mounts
3. **Monitor resource usage** with `htop` during builds
4. **Build packages sequentially** for Rust packages to avoid memory exhaustion


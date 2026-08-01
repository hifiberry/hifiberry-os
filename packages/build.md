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


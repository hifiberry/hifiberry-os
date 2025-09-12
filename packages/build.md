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


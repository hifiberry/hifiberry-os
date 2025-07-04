# HiFiBerry OS Meta-Packages

This directory contains the source for HiFiBerry OS meta-packages that provide convenient ways to install different configurations of HiFiBerry OS components. These meta-packages allow users to choose between minimal, testing, or full installations based on their needs.

## Available Packages

### hbos-minimal

A minimal meta-package that includes only the essential components for basic HiFiBerry OS functionality:

- `hifiberry-baseconfig` - Base system configuration and hardware detection
- `hifiberry-configurator` - Web-based configuration interface
- `hifiberry-eeprom` - HAT EEPROM tools and utilities
- `hifiberry-webui` - Modern web interface for system management

This package is ideal for users who want a lightweight installation with just the core functionality.

### hbos-test

A testing meta-package that extends the minimal installation with development and testing tools:

- All components from `hbos-minimal`
- `hifiberry-testtools` - Testing and development utilities
- Additional debugging and diagnostic tools

This package is designed for developers and advanced users who need testing capabilities.

### hbos-full

A comprehensive meta-package that includes all available HiFiBerry OS components:

- All components from `hbos-minimal`
- Audio streaming services:
  - `hifiberry-librespot` - Spotify Connect support
  - `hifiberry-shairport-sync` - AirPlay support
  - `hifiberry-squeezelite` - Squeezebox/Logitech Media Server support
  - `hifiberry-mpd` - Music Player Daemon
  - `hifiberry-snapcast` - Multi-room audio streaming
- Development and testing tools
- Python libraries and utilities
- DSP toolkit for advanced audio processing

This package provides the complete HiFiBerry OS experience with all features enabled.

## Building

To build all meta-packages using sbuild:

```bash
./build.sh
```

The build process will create `.deb` packages for all three meta-packages in the parent directory.

To clean build artifacts:

```bash
./clean.sh
```

## Installation

After building, you can install any of the meta-packages. Choose the one that best fits your needs:

### Minimal Installation

```bash
sudo dpkg -i hbos-minimal_*.deb
sudo apt-get install -f  # Fix any dependency issues
```

### Testing/Development Installation

```bash
sudo dpkg -i hbos-test_*.deb
sudo apt-get install -f  # Fix any dependency issues
```

### Full Installation

```bash
sudo dpkg -i hbos-full_*.deb
sudo apt-get install -f  # Fix any dependency issues
```

## Prerequisites

These meta-packages depend on the individual HiFiBerry OS component packages being available in your package repositories. You have several options:

1. **Build all components first**: Use the `build-all` script in the parent packages directory
2. **Use HiFiBerry repositories**: Add the HiFiBerry APT repository to your system
3. **Install individual packages**: Build and install the required component packages manually

## Package Management

- **Upgrading**: Simply install a newer version of the meta-package
- **Switching variants**: You can switch between minimal, test, and full variants by installing the desired meta-package
- **Removing**: Use `sudo apt-get remove <package-name>` to remove a meta-package (this will not remove the individual component packages)

## Package Versions

The packages follow semantic versioning:

- **Major version**: Breaking changes or significant feature additions
- **Minor version**: New features or component additions
- **Patch version**: Bug fixes and small improvements

Update the version in `src/debian/changelog` when making changes.

## Troubleshooting

If you encounter dependency issues during installation:

1. Ensure all component packages are built and available
2. Update your package index: `sudo apt-get update`
3. Fix broken dependencies: `sudo apt-get install -f`
4. Check for conflicting packages: `dpkg -l | grep hifiberry`

For more detailed information about individual components, refer to their respective documentation in the parent packages directory.

# HiFiBerry OS Meta-Packages

This directory contains the source for HiFiBerry OS meta-packages that provide convenient ways to install either a minimal or full set of HiFiBerry OS components.

## Packages

### hbos-minimal
A minimal meta-package that includes only the essential components:
- `hifiberry-baseconfig` - Base system configuration
- `hifiberry-configurator` - Web-based configuration interface
- `hifiberry-eeprom` - HAT EEPROM tools

### hbos-test
A testing meta-package that includes the minimal components plus testing tools:
- All components from hbos-minimal
- `hifiberry-testtools` - Testing and development utilities

### hbos-full
A comprehensive meta-package that includes all available HiFiBerry OS components:
- All components from hbos-minimal
- Audio streaming services (Spotify, AirPlay, etc.)
- Development and testing tools
- Python libraries and utilities

## Building

To build the packages using sbuild:

```bash
./build.sh
```

To clean build artifacts:

```bash
./clean.sh
```

## Installation

After building, you can install any of the packages:

```bash
# For minimal installation
sudo dpkg -i hbos-minimal_*.deb
sudo apt-get install -f  # Fix any dependency issues

# For testing/development installation
sudo dpkg -i hbos-test_*.deb
sudo apt-get install -f  # Fix any dependency issues

# For full installation  
sudo dpkg -i hbos-full_*.deb
sudo apt-get install -f  # Fix any dependency issues
```

## Dependencies

These meta-packages depend on the individual HiFiBerry OS component packages being available in your package repositories. Make sure to build and install the component packages first, or have them available in your APT repositories.

## Package Versions

The packages follow semantic versioning. Update the version in `src/debian/changelog` when making changes.

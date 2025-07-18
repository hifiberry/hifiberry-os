# HiFiBerry Bluetooth Audio Package

This package provides Bluetooth audio management tools for HiFiBerry systems.

## Features

- Bluetooth device pairing and management
- Audio codec configuration
- Integration with HiFiBerry audio systems

## Usage

```bash
# Check Bluetooth status
btaudio-config --status

# Scan for devices
btaudio-config --scan

# Pair with a device
btaudio-config --pair AA:BB:CC:DD:EE:FF
```

## Configuration

Configuration files are located in `/etc/hifiberry/btaudio.conf`.

## License

MIT License - see debian/copyright for details.

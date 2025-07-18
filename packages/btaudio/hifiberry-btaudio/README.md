# HiFiBerry Bluetooth Audio Package

This package provides Bluetooth audio management tools for HiFiBerry systems with secure pairing support.

## Features

- Bluetooth device pairing and management
- Audio codec configuration
- Integration with HiFiBerry audio systems
- Secure pairing with PIN codes or passkey confirmation
- Automatic hostname-based device naming

## Usage

### Basic Operations
```bash
# Check Bluetooth status
btaudio-config --status

# Make discoverable
btaudio-config --discoverable

# Hide from discovery
btaudio-config --hide

# Scan for devices
btaudio-config --scan

# Pair with a device
btaudio-config --pair AA:BB:CC:DD:EE:FF
```

### Secure Pairing
```bash
# Set a PIN code for secure pairing
btaudio-config --set-pin 1234

# Generate a random PIN and save it
btaudio-config --generate-pin

# Show current PIN from configuration
btaudio-config --show-pin

# Use different pairing modes
btaudio-config --set-pin 1234 --secure-pairing DisplayOnly

# Disable secure pairing agent
btaudio-config --disable-pairing
```

### PIN Management
```bash
# Set PIN using helper script
btaudio-pin --set-pin 1234

# Remove PIN (use passkey confirmation)
btaudio-pin --remove-pin

# Show current PIN setting
btaudio-pin --show-pin

# Generate PIN using system script
btaudio-generate-pin --generate

# Ensure PIN exists (used by installation)
btaudio-generate-pin --ensure-pin
```

## Secure Pairing Modes

- **DisplayYesNo**: Show passkey and ask for confirmation (default)
- **DisplayOnly**: Show PIN/passkey only (for devices with PIN input)
- **KeyboardDisplay**: Support both input and display
- **NoInputNoOutput**: No user interaction (least secure)

## Configuration

Configuration files are located in `/etc/hifiberry/btaudio.conf`.

Key settings:
- `bluetooth.pin=` - Set PIN code (4-8 digits)
- `bluetooth.pairing_mode=` - Set pairing mode
- `bluetooth.device_name=` - Set device name (empty = use hostname)

### Automatic PIN Generation

During installation, a random 4-digit PIN is automatically generated if none exists. This PIN is displayed during installation and can be viewed later with:

```bash
btaudio-config --show-pin
# or
cat /etc/hifiberry/btaudio.conf | grep bluetooth.pin
```

## Service Management

```bash
# Start/stop the discoverable service
systemctl start hifiberry-btaudio
systemctl stop hifiberry-btaudio

# Check service status
systemctl status hifiberry-btaudio

# View service logs
journalctl -u hifiberry-btaudio -f
```

## Security Considerations

- **PIN Pairing**: Most secure, requires PIN entry on connecting device
- **Passkey Confirmation**: Secure, shows passkey for verification
- **Auto-pairing**: Less secure but convenient for trusted environments

## License

MIT License - see debian/copyright for details.

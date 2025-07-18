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

### Managing Paired Devices
```bash
# List all paired devices
btaudio-config --list-paired

# Remove a specific device
btaudio-config --remove-device AA:BB:CC:DD:EE:FF

# Remove all paired devices
btaudio-config --remove-all
```

### Audio Profile Configuration
```bash
# Check if audio profiles are properly configured
btaudio-config --check-audio

# Setup Bluetooth audio profiles (A2DP sink)
btaudio-config --setup-audio

# Check audio backend status
btaudio-setup-audio --check

# Configure audio backend (PipeWire/PulseAudio)
btaudio-setup-audio --setup
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

## Troubleshooting

### iPhone/Phone Connects but Doesn't See System as Speaker

This is a common issue. The phone connects but doesn't recognize the system as an audio device:

1. **Check audio profiles are configured:**
   ```bash
   btaudio-config --check-audio
   ```

2. **Setup audio profiles if needed:**
   ```bash
   btaudio-config --setup-audio
   ```

3. **Ensure system is discoverable with audio capabilities:**
   ```bash
   btaudio-config --discoverable
   ```

4. **Check audio backend is configured:**
   ```bash
   btaudio-setup-audio --check
   btaudio-setup-audio --setup
   ```

5. **Restart Bluetooth service:**
   ```bash
   sudo systemctl restart bluetooth
   systemctl restart hifiberry-btaudio
   ```

6. **On the phone:**
   - Remove/unpair the device from phone settings
   - Re-pair the device
   - Look for the device in audio output options (not just Bluetooth settings)

### Common Solutions

- **Device Class**: Ensure the Bluetooth adapter is configured with audio device class (0x200414)
- **UUIDs**: A2DP Sink and AVRCP Target profiles must be advertised
- **Audio Backend**: PipeWire or PulseAudio Bluetooth modules must be loaded
- **Permissions**: Audio services need proper permissions to access Bluetooth

### Debug Commands

```bash
# Check Bluetooth status
btaudio-config --status

# Check what the phone sees
bluetoothctl info <PHONE_MAC_ADDRESS>

# Monitor Bluetooth events
journalctl -u bluetooth -f

# Check audio service status
systemctl status hifiberry-btaudio
```

## License

MIT License - see debian/copyright for details.

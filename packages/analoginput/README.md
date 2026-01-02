# HiFiBerry Analog Input Service

This package provides analog input management functionality for HiFiBerry audio systems. It connects ALSA ADC nodes to effect_input.proc using PipeWire.

## Building

To build the Debian package:

```bash
./build.sh
```

To clean build artifacts:

```bash
./clean.sh
```

## Installation

```bash
sudo dpkg -i hifiberry-analoginput_*.deb
```

## Usage

You can manually connect or disconnect the analog input:

```bash
# Connect analog input
hifiberry-analoginput connect

# Disconnect analog input
hifiberry-analoginput disconnect

# Verbose mode
hifiberry-analoginput connect -v
```

The service can be controlled via systemd as a user service:

```bash
systemctl --user start analoginput
systemctl --user stop analoginput
systemctl --user status analoginput
systemctl --user enable analoginput  # Enable at login
```

## Requirements

- PipeWire (pipewire, pw-cli, pw-link)
- ALSA ADC node starting with `alsa_input.platform-soc`
- Effect input node named `effect_input.proc`

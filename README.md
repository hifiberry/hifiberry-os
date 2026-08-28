# HiFiBerryOS Next Generation

The next-generation HiFiBerryOS is a complete rewrite, now based on a standard Debian distribution. It uses Debian packages to install tools, audio players, and the user interface, making it more flexible and modular.

## Documentation

- [Add your own player](docs/add-your-own-player.md)
- [Power key](docs/power-key.md) — stop the power button on a remote from shutting the system down

## Reporting bugs

Bug reports and feature requests belong in the
[issue tracker](https://github.com/hifiberry/hifiberry-os/issues/new/choose).
Bug reports ask for the output of `config-supportinfo`, which collects the
hardware, package versions and recent errors we need.

Questions about setup, hardware or purchases are better placed with
[HiFiBerry support](https://support.hifiberry.com/forum/c/software).

## Architecture

The system is composed of several core components:

### PipeWire

We use **PipeWire** as a system daemon to manage concurrent access to the sound card by multiple players.

### AudioControl

[AudioControl](https://github.com/hifiberry/acr) is our central control service. It manages audio routing and integrates with player backends and the web user interface.

### WebUI

The WebUI is a static Vue application, installed to `/usr/share/hifiberry/webui`
and served by **nginx**, which is the device's single front door on port 80.

nginx also reverse-proxies every backend service. Each package ships its own nginx
snippet, so a service's API prefix exists only when that package is installed:

| Prefix | Upstream |
|---|---|
| `/api/audiocontrol/` | AudioControl on `127.0.0.1:1080` |
| `/api/config/` | Configurator on `localhost:1081` |
| `/api/auth/` | hifiberry-auth on `127.0.0.1:1089` |
| `/api/roomeq/` | RoomEQ on `127.0.0.1:10315` |

The prefix is rewritten before the request reaches the backend — `/api/audiocontrol/`
becomes `/api/` on port 1080 — so a service's own documentation describes paths
without the prefix.

When the `hifiberry-auth` package is installed it adds an `auth_request` at server
level, so nginx gates every `/api/<service>/` location and the individual services
do not implement authentication themselves. Without that package the device is
ungated.

### Players

Audio players are provided as standalone packages. You only need to install the ones you intend to use. Available players include:

- [**MPD**](https://www.musicpd.org/) – plays local music files (MP3, WAV, FLAC, etc.)
- [**Librespot**](https://github.com/librespot-org/librespot) – provides Spotify Connect support
- [**Raat**](https://roonlabs.com/) – Roon audio playback (via the Roon Bridge)
- [**Shairplay**](https://github.com/juhovh/shairplay) – AirPlay 2 implementation
- [**Squeezelite**](https://github.com/ralph-irving/squeezelite) – Logitech Media Server client

More players may be added in the future. You can also package and install your own player. To make it visible and controllable through AudioControl/WebUI, see [Add your own player](docs/add-your-own-player.md).

## Hardware Recommendations

### Minimum Requirements

HiFiBerryOS runs on any 64-bit Raspberry Pi (Pi 3, Pi 4, or Pi 5) with a compatible HiFiBerry HAT. The system requires:

- **RAM**: 1GB minimum (2GB+ recommended for better performance)
- **Storage**: 8GB microSD card minimum (16GB+ recommended)
- **Network**: Ethernet or Wi-Fi connectivity

### Performance Considerations

**For streaming applications only:**
- Any Pi 3, Pi 4, or Pi 5 will provide excellent performance
- Standard microSD card storage is sufficient
- Wi-Fi connectivity works well for most use cases

**For large local music libraries (1000+ albums):**
- **Pi 5 with SSD highly recommended** for optimal performance
- SSD storage significantly improves library scanning and indexing
- Ethernet connection preferred for network-attached storage (NAS) access
- Consider Pi 4 with 4GB+ RAM as a cost-effective alternative

### Storage Options

- **microSD Card**: Suitable for streaming and small local libraries
- **USB 3.0 SSD**: Best performance for large libraries and frequent database operations
- **Network Storage**: NAS or network shares work well with sufficient network bandwidth

### HiFiBerry HAT Compatibility

HiFiBerryOS supports all current HiFiBerry audio HATs. No sound cards from other manufacturers are supported.

## Installation

To install HiFiBerryOS, start with [**Raspberry Pi OS Lite**](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-64-bit) and add the required packages.


### Add repository

Start adding the HiFiBerry debian repository:
```
curl -Ls https://raw.githubusercontent.com/hifiberry/hifiberry-os/refs/heads/main/addrepo | bash
```

### Package installation

The install-all script will install the minimal base packages:

```
curl -Ls https://raw.githubusercontent.com/hifiberry/hifiberry-os/refs/heads/main/install-all | bash
```

### Install all players

Install a full or minimal set of packages. The full set includes all players, while the minimal comes only with mpd. We recommend the full installation for most users:

```
sudo apt install -y hbos-full
```

If you prefer a minimal installation and want to install only the players you really need:
```
sudo apt install -y hbos-minimal
```

### Base configuration

```
sudo config-configtxt --default-config --enable-i2c
sudo reboot
```

### Set up Kiosk Mode

Activate a lightweight Kiosk mode that presents the UI on the device.
This replaces either the default Desktop (Raspberry Pi OS), or the terminal output (Raspberry Pi OS Lite).

[Instructions](docs/kiosk-mode.md)

## How to use

Open the WebUI at http://<device-ip>:80/ to start the initial setup wizard. It will guide you through sound card selection, system naming, and service configuration.


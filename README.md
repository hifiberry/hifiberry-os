# HiFiBerryOS Next Generation

The next-generation HiFiBerryOS is a complete rewrite, now based on a standard Debian distribution. It uses Debian packages to install tools, audio players, and the user interface, making it more flexible and modular.

## Architecture

The system is composed of several core components:

### PipeWire

We use **PipeWire** as a system daemon to manage concurrent access to the sound card by multiple players.

### AudioControl

[AudioControl](https://github.com/hifiberry/acr) is our central control service. It manages audio routing and integrates with player backends and the web user interface.

### WebUI

The WebUI is served directly by AudioControl, which includes a built-in web server.

### Players

Audio players are provided as standalone packages. You only need to install the ones you intend to use. Available players include:

- [**MPD**](https://www.musicpd.org/) – plays local music files (MP3, WAV, FLAC, etc.)
- [**Librespot**](https://github.com/librespot-org/librespot) – provides Spotify Connect support
- [**Raat**](https://roonlabs.com/) – Roon audio playback (via the Roon Bridge)
- [**Shairplay**](https://github.com/juhovh/shairplay) – AirPlay 2 implementation
- [**Squeezelite**](https://github.com/ralph-irving/squeezelite) – Logitech Media Server client

More players may be added in the future. You can also package and install your own player. However, to be visible and controllable through the WebUI, a player-specific module must be implemented for AudioControl.

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

HiFiBerryOS supports all current HiFiBerry audio HATs. No soudn cards from other manufacturers are supported.

## Installation

To install HiFiBerryOS, start with [**Raspberry Pi OS Lite**](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-legacy) and add the required packages.

### Add repository

Start adding the HiFiBerry debian repository:
```
curl -Ls https://tinyurl.com/hbosrepo | bash
```

### Package installation

Install a full or minimal set of packages. The full set included all players, while the minimal comes only with mpd. This allows you to install only the players you really need.

```
sudo apt install hbos-minimal
```
or
```
sudo apt install hbos-full
```

### Base configuration

```
sudo hifiberry-baseconfig --force
```

Then reboot

## How to use

The WebUI is accessible at: http://<device-ip>:1080/ui/index.html


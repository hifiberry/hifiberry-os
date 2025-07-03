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

## Installation

To install HiFiBerryOS, start with [**Raspberry Pi OS Lite**](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-legacy) and add the required packages.

### Full Installation

Coming soon...

### Minimal/Base Installation (No Players)

If you only need a specific player (e.g., Roon), you don’t have to install the full system. Instead, install just the base system and your desired player. This can significantly reduce the system footprint, especially for players with many dependencies.

## Web User Interface

The WebUI is accessible at: http://<device-ip>:1080/ui/index.html


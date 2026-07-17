# HiFiBerryOS Backend APIs

All backend services are reverse-proxied through **nginx on port 80**. The WebUI and all API calls go through this single entry point. No direct access to backend ports is needed from the browser.

> Access to these APIs is gated by an authentication/authorization layer. See the [Security Model](security-model.md) for how requests are classified (`ok` vs `risky`) and when a password is required.

## API Routing Overview

| Frontend Path | Backend | Port | Description |
|---|---|---|---|
| `/api/config/` | Configurator | 1081 | System configuration, hardware detection, sound cards |
| `/api/audiocontrol/` | AudioControl (ACR) | 1080 | Player management, playback control, metadata |
| `/api/dsptoolkit/` | SigmaTCP Server | 13141 | DSP programming, memory read/write, profiles |
| `/api/pipewire/` | PipeWire API | 2716 | Volume, mixer, balance, PipeWire node control |
| `/api/btaudio/` | Bluetooth Service | 1082 | Bluetooth audio device management |
| `/api/roomeq/` | RoomEQ | 10315 | Room acoustics measurement and correction |
| `/api/vu-meter/` | VU Meter | 2717 | Real-time audio level WebSocket |

## Nginx Configuration

- **Site config**: `/etc/nginx/sites-enabled/hifiberry`
- **API proxies**: `/etc/nginx/hifiberry-api.d/*.nginx` (one file per service)
- **WebUI static**: `/etc/nginx/hifiberry-webui.nginx`
- **Document root**: `/usr/share/hifiberry/webui`

Each API proxy strips its prefix before forwarding. For example:
- Browser requests: `GET /api/config/v1/soundcard/detect`
- Nginx forwards to: `GET http://localhost:1081/api/v1/soundcard/detect`

The DSP toolkit proxy uses a rewrite rule instead:
- Browser requests: `GET /api/dsptoolkit/profiles/metadata`
- Nginx rewrites and forwards to: `GET http://localhost:13141/profiles/metadata`

## Configurator API (`/api/config/`)

Backend: Python (Flask + Waitress), port 1081. Runs as root via `config-server.service`.

### System Info
- `GET /api/config/v1/system` — System information (hostname, pretty_hostname, uptime, etc.)
- `POST /api/config/v1/hostname` — Set hostname (`{"hostname": "..."}`)

### Sound Cards
- `GET /api/config/v1/soundcard/detect` — Detect current sound card (returns card_name, dtoverlay, features, supports_dsp)
- `GET /api/config/v1/soundcard/list` — List all available HiFiBerry sound cards
- `POST /api/config/v1/soundcard/dtoverlay` — Set sound card dtoverlay (`{"dtoverlay": "..."}`)
- `POST /api/config/v1/soundcard/detection` — Enable/disable auto-detection (`{"enabled": true/false}`)

### Setup Wizard
- `GET /api/config/v1/setup/status` — Check if initial setup is completed
- `POST /api/config/v1/setup/complete` — Mark setup as completed
- `POST /api/config/v1/setup/reset` — Reset setup status (deletes `system.setup_completed` from ConfigDB)

### Systemd Services
- `GET /api/config/v1/service/<name>/status` — Get service status
- `POST /api/config/v1/service/<name>/enable` — Enable and start service
- `POST /api/config/v1/service/<name>/disable` — Disable and stop service
- `GET /api/config/v1/service/status/multiple` — Get status of multiple services (`?services=svc1,svc2`)
- `GET /api/config/v1/service/<name>/exists` — Check if a service unit exists

### Network / SMB
- `GET /api/config/v1/smb/mounts` — List SMB/NAS mounts
- `POST /api/config/v1/smb/mount` — Add an SMB mount
- `DELETE /api/config/v1/smb/mount` — Remove an SMB mount

### System Actions
- `POST /api/config/v1/reboot` — Reboot the system

### ConfigDB (Key-Value Store)
- `GET /api/config/v1/key/<key>` — Get a config value
- `POST /api/config/v1/key/<key>` — Set a config value
- `DELETE /api/config/v1/key/<key>` — Delete a config value

## AudioControl API (`/api/audiocontrol/`)

Backend: Rust (ACR), port 1080. Runs as system service via `audiocontrol.service`.

### Players
- `GET /api/audiocontrol/players` — List all registered players with state
- `GET /api/audiocontrol/player/active` — Get currently active player
- `POST /api/audiocontrol/player/<id>/play` — Play
- `POST /api/audiocontrol/player/<id>/pause` — Pause
- `POST /api/audiocontrol/player/<id>/stop` — Stop
- `POST /api/audiocontrol/player/<id>/next` — Next track
- `POST /api/audiocontrol/player/<id>/previous` — Previous track
- `POST /api/audiocontrol/player/<id>/seek` — Seek (`{"position": seconds}`)

### Now Playing
- `GET /api/audiocontrol/now-playing` — Current track metadata + album art

### Library (MPD)
- `GET /api/audiocontrol/library/albums` — List albums
- `GET /api/audiocontrol/library/artists` — List artists
- `GET /api/audiocontrol/library/genres` — List genres

### External Players (Drop-in Descriptors)
Player packages install JSON descriptors in `/etc/audiocontrol/players.d/` which ACR discovers at runtime.

## DSP Toolkit API (`/api/dsptoolkit/`)

Backend: Python (Flask + Waitress), port 13141. Runs as system service via `sigmatcpserver.service`.

### Hardware Detection
- `GET /api/dsptoolkit/hardware/dsp` — Detect DSP hardware presence

### DSP Metadata
- `GET /api/dsptoolkit/metadata` — Get metadata from loaded DSP profile (register addresses for volume, SPDIF, mute, etc.)
- `GET /api/dsptoolkit/profiles/metadata` — Get metadata for all available DSP profile files (includes modelName, profileName, profileVersion, checksum)

### Memory Read/Write
- `GET /api/dsptoolkit/memory/<address>` — Read DSP memory at address
- `GET /api/dsptoolkit/memory/<address>/<length>` — Read multiple words
- `POST /api/dsptoolkit/memory` — Write DSP memory (`{"address": ..., "value": ..., "store": true}`)

### Registers
- `GET /api/dsptoolkit/register/<address>` — Read register
- `POST /api/dsptoolkit/register` — Write register

### Program Info
- `GET /api/dsptoolkit/checksum` — Get checksum of currently loaded DSP program
- `GET /api/dsptoolkit/program-info` — Program info (length, version)
- `GET /api/dsptoolkit/program-length` — Program length
- `GET /api/dsptoolkit/version` — DSP toolkit version

### DSP Profile Management
- `GET /api/dsptoolkit/dspprofile` — Get current profile XML
- `POST /api/dsptoolkit/dspprofile` — Deploy a new DSP profile (`{"file": "/path/to/profile.xml"}`)

### Cache
- `GET /api/dsptoolkit/cache` — Get cache status (includes current profile name, metadata)
- `POST /api/dsptoolkit/cache/clear` — Clear profile cache

### Filters (IIR/Biquad)
- `GET /api/dsptoolkit/filters` — Get stored filters
- `POST /api/dsptoolkit/filters` — Store filters
- `DELETE /api/dsptoolkit/filters` — Delete stored filters
- `GET /api/dsptoolkit/filters/bypass` — Get filter bypass state
- `POST /api/dsptoolkit/filters/bypass` — Set filter bypass
- `PUT /api/dsptoolkit/filters/bypass` — Update filter bypass

### Frequency Response
- `POST /api/dsptoolkit/frequency-response` — Calculate frequency response from biquad coefficients

### Biquad
- `POST /api/dsptoolkit/biquad` — Calculate biquad coefficients

## PipeWire API (`/api/pipewire/`)

Backend: C/Rust, port 2716. Runs as user service via `pipewire-api.service`.

### Volume
- `GET /api/pipewire/v1/volume` — Get current volume
- `POST /api/pipewire/v1/volume` — Set volume

### Mixer / Balance
- `GET /api/pipewire/v1/balance` — Get balance
- `POST /api/pipewire/v1/balance` — Set balance

### Nodes
- `GET /api/pipewire/v1/nodes` — List PipeWire nodes

## Bluetooth API (`/api/btaudio/`)

Backend: Python, port 1082. Runs as system service via `hifiberry-bluetooth.service`.

### Device Management
- `GET /api/btaudio/devices` — List known Bluetooth devices
- `POST /api/btaudio/scan` — Start scanning
- `POST /api/btaudio/pair` — Pair with device
- `POST /api/btaudio/connect` — Connect to device
- `POST /api/btaudio/disconnect` — Disconnect from device
- `POST /api/btaudio/remove` — Remove/forget device

### Settings
- `GET /api/btaudio/settings` — Get Bluetooth settings (discoverable, pairable)
- `POST /api/btaudio/settings` — Update settings

## RoomEQ API (`/api/roomeq/`)

Backend: Rust/Python, port 10315. Runs as system service via `roomeq.service`.

Room acoustics measurement and equalization service.

## VU Meter API (`/api/vu-meter/`)

Backend: Rust, port 2717. Runs as user service via `vu-meter.service`.

Provides real-time audio level data via WebSocket connection.

- `WS /api/vu-meter/ws` — WebSocket for real-time VU meter data

## WebUI Frontend Configuration

The WebUI stores API base URLs in `src/stores/appconfig.ts`. The key mappings:

| Store Method | Nginx Path |
|---|---|
| `getConfigApiBaseUrl()` | `/api/config/v1` |
| `getDSPToolkitApiBaseUrl()` | `/api/dsptoolkit` |
| `getAudioControlApiBaseUrl()` | `/api/audiocontrol` |
| `getPipeWireApiBaseUrl()` | `/api/pipewire/v1` |

## Service Ports Summary (localhost only)

| Port | Service | Systemd Unit |
|---|---|---|
| 80 | nginx (public entry point) | `nginx.service` |
| 1080 | AudioControl (ACR) | `audiocontrol.service` |
| 1081 | Configurator (root) | `config-server.service` |
| 1082 | Bluetooth Service | `hifiberry-bluetooth.service` |
| 2716 | PipeWire API | `pipewire-api.service` (user) |
| 2717 | VU Meter | `vu-meter.service` (user) |
| 10315 | RoomEQ | `roomeq.service` |
| 13141 | SigmaTCP/DSP Toolkit | `sigmatcpserver.service` |

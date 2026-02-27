# Add your own player (ACR)

This guide is based on the latest ACR changes (0.6.18), especially:

- `players.d/` include directory support
- configurable `generic` player capabilities
- Web UI player registry (drop-in descriptor + icon)

Use this when you want to integrate an external/custom player without writing a new Rust controller first. Your player can appear in the Web UI's Services > Players page automatically by dropping a few files into well-known directories.

## 1) Add a player config in `players.d/`

ACR now merges `*.json` files from a `players.d/` directory next to your main ACR config file.

- Files are loaded in alphabetical order.
- Each file can contain either one player object or an array of player objects.
- Invalid JSON files are skipped (with warnings), they do not stop startup.

Example file: `players.d/10-myplayer.json`

```json
{
  "generic": {
    "name": "my-player",
    "enable": true,
    "initial_state": "stopped",
    "shuffle": false,
    "loop_mode": "none",
    "capabilities": [
      "play",
      "pause",
      "stop",
      "next",
      "previous",
      "seek",
      "shuffle",
      "loop",
      "metadata"
    ]
  }
}
```

Notes:

- `name` is required for `generic` players.
- `enable` defaults to `true` if omitted.
- Player types that start with `_` are ignored.

## 2) Choose capabilities explicitly

`generic` players now read `capabilities` from JSON. This lets you expose only the controls your external player really supports.

Supported capability names:

- `play`, `pause`, `play_pause`, `stop`
- `next`, `previous`, `seek`, `position`, `length`
- `volume`, `mute`, `shuffle`, `loop`
- `playlists`, `queue`, `metadata`, `album_art`
- `search`, `browse`, `favorites`, `db_update`
- `killable`, `receives_updates`

If omitted, ACR falls back to generic defaults (`play/pause/stop/next/previous/seek/loop/shuffle/killable`).

## 3) Send runtime updates from your player bridge

Generic players always accept API updates through:

`POST /api/player/<player_name>/update`

Example:

```bash
curl -X POST http://localhost:1080/api/player/my-player/update \
  -H 'Content-Type: application/json' \
  -d '{"type":"state_changed","state":"playing"}'
```

Useful event payloads:

- state change: `{"type":"state_changed","state":"playing|paused|stopped|killed|disconnected|unknown"}`
- song change: `{"type":"song_changed","song":{"title":"...","artist":"...","album":"...","duration":123.4,"uri":"..."}}`
- position: `{"type":"position_changed","position":42.0}`
- loop mode: `{"type":"loop_mode_changed","loop_mode":"none|song|track|playlist"}`
- shuffle: `{"type":"shuffle_changed","shuffle":true}`

## 4) Verify in ACR API

Check player registration:

```bash
curl http://localhost:1080/api/players
```

You should see your player by `name`, with `type: generic`, and the capabilities you configured.

## 5) Register in the Web UI

To make your player appear on the **Services > Players** page with a toggle switch, drop three files:

### a) Player descriptor

Create `/etc/hifiberry/players.d/<name>.json`:

```json
{
    "name": "My Player",
    "provided_by": "my-player-package",
    "systemd_service": "my-player",
    "icon": "my-player",
    "allow_change": true
}
```

Fields:
- `name` — display name in the UI
- `provided_by` — short identifier shown as subtitle
- `systemd_service` — the systemd service to start/stop
- `icon` — icon filename (without `.svg`), resolved from the icons directory
- `allow_change` — whether the toggle switch is enabled (default: `true`)

### b) Icon

Place an SVG icon at `/etc/hifiberry/players.d/icons/<icon>.svg`.

The icon is served by the configurator API and displayed as a 40x40 image. Use `currentColor` for fill/stroke to match the UI theme.

### c) Systemd permissions

Create `/etc/configserver/conf.d/<name>.json` to grant the configurator permission to manage your service:

```json
{
    "systemd": {
        "my-player": "all"
    }
}
```

This uses the configserver's drop-in config support — no need to edit `configserver.json` directly.

### Verify

After dropping the files, restart the configurator (`sudo systemctl restart config-server`) and open the Players page. Your player should appear with a working on/off toggle.

```bash
# Check the player registry API
curl http://localhost:1081/api/v1/players

# Check the icon is served
curl -I http://localhost:1081/api/v1/players/icon/my-player
```

## 6) Complete example: all files for an external player

Here is the full set of drop-in files needed for a player called "my-player":

| File | Purpose |
|------|---------|
| `/etc/audiocontrol/players.d/my-player.json` | ACR player config (audio routing + metadata) |
| `/etc/hifiberry/players.d/my-player.json` | Web UI descriptor (name, icon, service) |
| `/etc/hifiberry/players.d/icons/my-player.svg` | SVG icon for the UI |
| `/etc/configserver/conf.d/my-player.json` | Systemd permissions for start/stop |

No code changes required — everything is pure drop-in.

## 7) Example: Spotify/librespot as a community plugin

The `hifiberry-librespot` package is a real-world example of a native Debian package (no Docker) that registers itself using the drop-in mechanism. Its `postinst` creates three files on install:

- `/etc/hifiberry/players.d/librespot.json` — UI descriptor (name: "Spotify", service: "librespot")
- `/etc/hifiberry/players.d/icons/librespot.svg` — Spotify icon (stroke-based SVG)
- `/etc/configserver/conf.d/librespot.json` — systemd permission (`"librespot": "all"`)
- `/etc/audiocontrol/players.d/librespot.json` — ACR player registration

Its `postrm` removes all four files on uninstall. The icon SVG is shipped inside the package at `/usr/share/hifiberry-librespot/icons/spotify.svg` and copied to the drop-in directory during `postinst`.

This pattern works for any Debian-packaged player — no Docker required.

## 8) When to implement a native Rust controller

Use `generic` + update API when your external process can publish its state via HTTP.

Create a native player in `src/players/` and register it in `player_factory.rs` when you need deeper integration (custom transport, discovery, queue/library control, tighter lifecycle handling).

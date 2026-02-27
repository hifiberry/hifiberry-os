# Add your own player (ACR)

This guide is based on the latest ACR changes (0.6.18), especially:

- `players.d/` include directory support
- configurable `generic` player capabilities

Use this when you want to integrate an external/custom player without writing a new Rust controller first.

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

## 5) When to implement a native Rust controller

Use `generic` + update API when your external process can publish its state via HTTP.

Create a native player in `src/players/` and register it in `player_factory.rs` when you need deeper integration (custom transport, discovery, queue/library control, tighter lifecycle handling).

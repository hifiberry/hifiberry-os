# Sendspin Player for HiFiBerryOS — Design

**Status:** Approved design, ready for implementation plan
**Date:** 2026-07-08

## Goal

Add a **Sendspin player** to HiFiBerryOS so Music Assistant (MA) can stream to a
HiFiBerry device over its native Sendspin protocol, carrying reliable metadata
(title/artist/album/cover art/progress) and supporting **bidirectional
transport + volume control**. Delivered as a plugin-type deb package, structured
like the existing `shairport-sync`/`librespot` players.

## Motivation

MA↔AirPlay 2 does not deliver metadata to HiFiBerryOS: shairport-airplay2 emits
metadata to its pipe but not to the UDP port audiocontrol reads. Sendspin is MA's
native multiroom protocol and carries metadata natively, so it is the correct
long-term path for the MA use case.

## Architecture

Three deliverables across three locations:

1. **New repo `github.com/hifiberry/sendspin`** — the C++ daemon (`sendspind`),
   its ALSA sink, ACR reporter, HTTP command listener, mDNS advertiser, and its
   **own** `debian/` packaging + build script. Wraps `sendspin-cpp`. This mirrors
   the `acr` / `configurator` pattern (separate repo carrying its own packaging).
2. **ACR enhancement (`github.com/hifiberry/acr`)** — add an outbound
   `command_url` to the generic player so transport commands from the HiFiBerry
   UI actually reach the daemon. Version bump to **0.7.15**.
3. **hifiberry-os `packages/sendspin/`** (this repo) — a thin `build.sh` that
   clones/updates the new repo and invokes its build, plus `clean.sh` and a
   `.gitignore` entry for `packages/sendspin/sendspin`. Exactly the
   acr/configurator shape.

The daemon and the ACR change are coupled by the command protocol, so they are
covered by this single spec as two clearly-bounded components.

## Global Constraints

- **Audio output PCM device is ALSA `default`** (routes through PipeWire for
  mixing) — never a `hw:` device. Neither shairport nor librespot passes an
  output device; both already use `default`.
- **Volume rides the ALSA mixer control discovered via `config-soundcard`**, on
  `hw:<index>` — the same physical control ACR's global volume auto-detects and
  monitors. On the reference device (tannoy, DAC+/Amp2) that control is `Digital`
  on `hw:0`.
- **Device discovery is done in the systemd start wrapper**, not compiled into
  the daemon — matching `start-shairport.sh` / `start-librespot.sh`.
- **Player identity advertised to MA = the pretty hostname**
  (`hostnamectl hostname --pretty`), like shairport/librespot.
- Runs as a **user** systemd service, `After=pipewire.service`, guarded by
  `config-soundcard --detect`.
- Command port is the fixed constant **3547**; the start wrapper passes
  `--command-port 3547` and `players.d/sendspin.json` hard-codes
  `http://127.0.0.1:3547/command`. One constant, both sides agree.
- ACR `command_url` must be **backward-compatible**: absent → today's
  log-and-mutate behaviour, unchanged for all other generic players.
- Never install via pip; deb packages only. No `Co-Authored-By` in commits.

## Components

### Component A — `sendspind` daemon (new repo)

Wraps `sendspin-cpp` (CMake FetchContent/submodule; deps ArduinoJson, micro-flac,
micro-opus, IXWebSocket). Registers the player, metadata, and controller roles.

Sub-units, each with one responsibility:

- **Sendspin client** — player role (audio render), metadata role (track info),
  controller role (transport → MA). Runs the main loop `client.loop()` + 10 ms
  sleep.
- **ALSA sink** — opens PCM `default`; SPSC ring buffer bridges the
  `on_audio_write` push callback to a dedicated ALSA writer thread (the
  `portaudio_sink` pattern, ALSA instead of PortAudio). Configured on
  `on_stream_start()` from `player.get_current_stream_params()`.
- **Volume control** — `snd_mixer` on the discovered control / `hw:<index>`.
  Applies MA volume/mute; a monitor thread polls for local changes and reports
  them up. Set-if-changed in both directions.
- **ACR reporter** — POSTs `state_changed` / `song_changed` / `position_changed`
  to `http://localhost:1080/api/player/sendspin/update`. Non-blocking queue: a
  slow/absent ACR never stalls audio.
- **HTTP command listener** — tiny HTTP server on port 3547; ACR POSTs transport
  commands here; the daemon emits the matching Sendspin controller message.
- **mDNS advertiser** — advertises `_sendspin._tcp` (avahi/`libavahi-compat`) as
  the pretty hostname.

**Start wrapper** `/usr/bin/start-sendspin` (installed by the deb), invoked by the
systemd unit — does discovery like the other players:

```sh
/usr/bin/config-soundcard --detect >/dev/null 2>&1 || exit 0   # no card → idle
NAME=$(hostnamectl hostname --pretty 2>/dev/null); [ -n "$NAME" ] || NAME=$(hostname)
MIXER=$(config-soundcard --no-eeprom --volume-control-softvol 2>/dev/null)
HWIDX=$(config-soundcard --no-eeprom --hw 2>/dev/null)
exec /usr/bin/sendspind \
  --alsa-device default \
  --mixer-control "$MIXER" --mixer-device "hw:$HWIDX" \
  --command-port 3547 \
  --acr-url http://localhost:1080/api/player/sendspin/update \
  --name "$NAME"
```

### Component B — ACR generic-player `command_url` (acr repo)

- Add optional `command_url: Option<String>` to the generic player config.
- In `send_command(cmd)`: when `command_url` is set, serialise the command to
  JSON and POST it with **ureq** (already a dependency; tokio-free sync HTTP).
  Keep the existing internal-state update as an optimistic reflection that
  Flow B's echo-back corrects. When absent, behaviour is unchanged.
- Version bump `Cargo.toml` + `debian/changelog` to **0.7.15**.
- Unit test: `send_command` with `command_url` set POSTs the expected JSON to a
  mock endpoint; with `command_url` absent, no POST and state still mutates.

### Component C — hifiberry-os `packages/sendspin/` (this repo)

- `build.sh` — clone/update `https://github.com/hifiberry/sendspin` into
  `packages/sendspin/sendspin` (gitignored), then invoke its build script;
  collect `*.deb`. Same shape as `packages/configurator/build.sh`.
- `clean.sh` — remove the checkout + build artifacts.
- `.gitignore` — add `packages/sendspin/sendspin`.

## Data Flows

### Connection lifecycle

On start the daemon advertises `_sendspin._tcp` as the pretty hostname and listens
on its Sendspin port. MA discovers and connects; sendspin-cpp negotiates roles and
audio formats (FLAC/Opus/PCM) and runs its handshake (encrypted if MA requires it;
sendspin-cpp handles this internally). ACR does **not** discover the daemon — ACR
statically loads the `sendspin` generic player from `players.d` at its own startup;
the daemon POSTs updates whenever connected.

### Flow A — Audio (MA → speaker)

`on_stream_start()` reads `player.get_current_stream_params()` (rate/channels/bits)
and configures the ALSA `default` PCM. sendspin-cpp decodes frames and calls
`on_audio_write(data,len,timeout)`; the daemon pushes PCM into the SPSC ring buffer
and the ALSA writer thread pulls and writes to `default`. `on_stream_end()`
drains/clears the PCM.

### Flow B — Metadata & state up (speaker → ACR → UI)

`on_metadata(md)` → POST `song_changed` with title/artist/album/duration +
**`artwork_url`** (the ACR 0.7.14 alias → `cover_art_url`). Stream start/end and
play/pause → POST `state_changed`. Progress → periodic `position_changed`. ACR's
generic player reflects them; the data-driven WebUI shows now-playing + cover art.

Report contract (`POST /api/player/sendspin/update`):

```json
{ "type": "state_changed", "state": "playing|paused|stopped" }
{ "type": "song_changed", "song": { "title": "...", "artist": "...",
    "album": "...", "duration": 214.0, "artwork_url": "http://.../cover.jpg" } }
{ "type": "position_changed", "position": 42.5 }
```

### Flow C — Transport commands down (UI/buttons → MA)

UI/hardware button → ACR generic player `send_command()` → (new `command_url`) ACR
POSTs to the daemon's `http://127.0.0.1:3547/command` → daemon emits the matching
Sendspin controller message to MA. MA acts; the real resulting state returns via
Flow B, so the UI reflects MA's actual response rather than an optimistic guess.

Command contract (ACR → daemon):

```json
{ "command": "play" }
{ "command": "pause" }
{ "command": "stop" }
{ "command": "next" }
{ "command": "previous" }
```

`PlayerCommand` → `SendspinControllerCommand` map: Play→`PLAY`, Pause→`PAUSE`,
Stop→`STOP`, Next→`NEXT`, Previous→`PREVIOUS`. **Seek is not supported** — the
Sendspin controller protocol (`controller_role.h`) has no SEEK command, so it is
not exposed as a capability. Repeat/shuffle exist in the protocol and are mapped
for forward-compatibility, but v1 UI wires only transport.

### Flow D — Volume (both ways), over the one hardware control

- MA → speaker: `on_volume_changed()` / `on_mute_changed()` → daemon sets the ALSA
  mixer control (from `config-soundcard`). ACR's global volume monitors that same
  control, so the UI updates automatically — no extra POST needed.
- Speaker → MA: any local change to that control (user knob, or ACR's own
  `set_volume`) is caught by the daemon's `snd_mixer` monitor → reported up to MA.

One physical control, every party observes it; set-if-changed avoids feedback
loops. Volume scaling: MA 0–100 ↔ the mixer control's dB/raw range.

## Packaging & Registration

Installed by the new repo's deb, mirroring shairport:

- `/etc/hifiberry/players.d/sendspin.json` (WebUI registry):
  ```json
  { "name": "Music Assistant", "provided_by": "sendspin",
    "systemd_service": "sendspin", "icon": "sendspin", "allow_change": true }
  ```
- `/etc/configserver/conf.d/sendspin.json` (WebUI control of the user service):
  ```json
  { "systemd": { "sendspin": "all" } }
  ```
- `/etc/audiocontrol/players.d/sendspin.json` (ACR generic player):
  ```json
  { "generic": {
      "name": "sendspin", "enable": true, "supports_api_events": true,
      "capabilities": ["play","pause","stop","next","previous","killable"],
      "command_url": "http://127.0.0.1:3547/command" } }
  ```
- An icon (e.g. `sendspin.svg`) alongside the WebUI registry, like shairport's
  `airplay.svg`.

**systemd user service** `sendspin.service`: `Type=simple`,
`ExecStart=/usr/bin/start-sendspin`, `After=sound.target network.target
pipewire.service`, `Wants=avahi-daemon.service`, `Restart=on-failure`,
`RestartSec=2`, `WantedBy=default.target`. Registered but toggled on via the
WebUI (`allow_change:true`) so it does not auto-disrupt existing setups.

**deb `control`:** `Depends: libasound2, libavahi-compat-libdnssd1,
hifiberry-configurator`; `Build-Depends: cmake, build-essential, libasound2-dev,
libavahi-compat-libdnssd-dev, git`.

## Error Handling & Edge Cases

- No sound card → start wrapper exits 0, service idle (shairport guard).
- ACR down / POST fails → reporter queue drops the update, **audio keeps
  playing**, retries on the next event.
- MA disconnects → report stopped, clear ALSA, keep advertising, await reconnect.
- ALSA `default` not ready (pipewire still starting) → open with backoff;
  `After=pipewire.service` mitigates.
- Command received with no MA connected → log no-op.
- Volume feedback loop → set-if-changed guard in both directions; mute
  saves/restores the level.
- Network change → re-advertise mDNS.

## Testing

- **Daemon unit tests** (pure logic, no audio hardware): command JSON →
  controller-message mapping; metadata → `song_changed` builder (incl.
  `artwork_url`); volume scaling (MA 0–100 ↔ mixer range); SPSC ring buffer.
- **ACR unit test:** `send_command` with `command_url` POSTs the correct JSON to
  a mock server; absent `command_url` → no POST, state still mutates.
- **Integration on tannoy (192.168.1.12), manual:** MA streams to the player →
  audio out via `default`; now-playing + cover art in the HiFiBerry UI; transport
  buttons drive MA; volume both directions over the `Digital` control.

## Out of Scope (v1)

- Seek from the HiFiBerry UI — the Sendspin controller protocol has no SEEK
  command, so the capability is not advertised.
- Shuffle/loop controls from the HiFiBerry UI (mapping present, UI not wired).
- Replacing the AirPlay path — Sendspin coexists as an additional input.
- Manual encryption toggles — rely on sendspin-cpp's negotiated handshake.

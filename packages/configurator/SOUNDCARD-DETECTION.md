# Sound Card Detection and Pinning

How HiFiBerryOS decides which sound card it is running on, and how the user
can override that decision (pin) via the setup wizard or the configurator
HTTP API.

This document describes the flow as of `hifiberry-configurator` 2.13.8.

## TL;DR

1. The configurator owns the source of truth for "what card is this?".
2. Other components (`config-soundcard`, `audiocontrol`, `start-librespot`,
   `start-raat`, the webui setup wizard) all ask the configurator — directly
   or via `config-soundcard` — and use the answer to pick mixer names,
   hardware indices, channel counts, DSP profiles, etc.
3. Pinning a card is a **persistent override**: it is written to **two**
   places (ConfigDB and `/boot/firmware/config.txt`), and the detector reads
   from either one before doing any actual hardware probing.

If pinning is broken, downstream things silently fall back to wrong defaults
(notably: `config-soundcard --volume-control-softvol` → `Softvol` →
librespot/raat ALSA-mixer init fails, even when the dsptoolkit is correctly
exposing `DSPVolume`).

## Components

| Component | File | Role |
|---|---|---|
| `SoundcardDetector` | `configurator/soundcard_detector.py` | Runs the actual detection ladder. Owns the override checks. |
| `Soundcard` | `configurator/soundcard.py` | Per-card metadata (name, dtoverlay, mixer, channels, …). |
| `SOUND_CARD_DEFINITIONS` | `configurator/soundcard.py` | The lookup table — every supported card lives here. |
| `config-soundcard` | `configurator/soundcard.py:main` | CLI front-end used by start-scripts. Wraps `Soundcard()`. |
| `SoundcardHandler` | `configurator/handlers/soundcard_handler.py` | HTTP handlers behind `/api/v1/soundcard/*`. Writes ConfigDB + `config.txt`. |
| `ConfigTxt` | `configurator/configtxt.py` | Reads / edits `/boot/firmware/config.txt` (overlays + HiFiBerry comments). |
| `ConfigDB` | `configurator/configdb.py` | Persistent key-value store for system-wide settings. |

## Detection ladder (`SoundcardDetector.detect_card`)

Steps run top-to-bottom; the first one that produces a valid card wins.

1. **Step 0 — ConfigDB override.** If `soundcard.name` is present in
   ConfigDB, use it verbatim. This is the primary "pinned" path written by
   the wizard.
2. **Step 0b — `config.txt` comment fallback.** If ConfigDB has nothing,
   read `# HiFiBerry card: <name>` from `/boot/firmware/config.txt` and use
   that. Back-compat path for systems pinned before the ConfigDB write
   existed (and a defense-in-depth path if the two ever drift).
3. **Step 1 — HAT EEPROM.** Read the Pi HAT EEPROM. Most modern HiFiBerry
   cards advertise their product name here.
4. **Step 2 — I2C probing.** Probe known device addresses (e.g. ADAU146x
   for DSP cards, PCM5122 family for DAC variants).
5. **Step 3 — `aplay -l` output.** Match against the loaded ALSA driver
   string.
6. **Step 4 — DSP detection.** Last-ditch: try to talk to a DSP at the
   expected address.

`Soundcard()` then takes the detector's `detected_card` string and looks it
up in `SOUND_CARD_DEFINITIONS` (or its `aliases` field) to populate the rest
of the attributes (volume_control, hw_index, channels, …).

### `_detect_card` vs `_detect_card_aplay_priority`

There are two `Soundcard._detect_card*` methods.

- `_detect_card(no_eeprom=…)` — runs the ladder above. **This is what
  `config-soundcard` uses.**
- `_detect_card_aplay_priority(no_eeprom=…)` — used by some internal flows
  that want to prioritize the *currently loaded* ALSA driver over the
  detector's verdict (e.g. when users manually edited overlays without going
  through the API). It checks the `config.txt` comment first, then aplay,
  then falls back to the regular detector for disambiguation.

Both honor the same pinned-card overrides, but `_detect_card` is the path
hit by every CLI/API caller in normal operation.

## Pinning a card

Pinning persists "this is the card to use" so the detection ladder can
short-circuit. Call:

```http
POST /api/v1/soundcard/detection/disable
Content-Type: application/json

{ "card_name": "Beocreate 4-Channel Amplifier" }
```

The handler (`SoundcardHandler.handle_disable_detection`) does the following
**atomically from the user's POV**, but as separate side effects internally:

1. Look up `card_name` in `SOUND_CARD_DEFINITIONS` to get its `dtoverlay`.
2. **`/boot/firmware/config.txt`:**
   - Remove any existing HiFiBerry overlays.
   - Add `# HiFiBerry sound detection disabled`.
   - Add `# HiFiBerry card: <name>` (read by Step 0b above).
   - Add `dtoverlay=<resolved_overlay>` (with `force_eeprom_read=0`).
3. **ConfigDB:** `soundcard.name = "<name>"` (read by Step 0 above).

A reboot is required for the new dtoverlay to take effect at the kernel
level — but `config-soundcard` will return the pinned card immediately,
because the override paths are read-only file/DB reads, not driver state.

### Re-enabling auto-detect

```http
POST /api/v1/soundcard/detection/enable
```

Mirror of the above:

1. Remove HiFiBerry overlays + comments from `config.txt`.
2. Add the `# HiFiBerry detection enabled` marker.
3. **`ConfigDB.delete("soundcard.name")`** so Step 0 stops short-circuiting.

If you only clean up one side, the next detection run will keep returning
the stale pin via whichever side you forgot.

## Why both ConfigDB and `config.txt`?

`config.txt` is the only place the **kernel** looks (for the dtoverlay
choice), so the dtoverlay has to live there.

ConfigDB is what userspace components query. Storing `soundcard.name` in
ConfigDB lets:

- `config-soundcard --name` and `--volume-control` answer correctly without
  parsing `config.txt`.
- Any future component avoid duplicating the comment-parsing logic.
- The override survive even if a user rewrites their own `config.txt`
  manually.

The `config.txt` comment is kept as a redundant copy because:

- It documents the user's choice in the same file as the dtoverlay (good
  for humans reading `config.txt`).
- It survives ConfigDB resets / migrations.
- It is the back-compat path for systems pinned before ConfigDB writes
  existed.

## Why this matters: the `Softvol` / `DSPVolume` pitfall

`start-librespot` (and the equivalent for raat / Roon) picks its ALSA
mixer like this:

```bash
MIXER_NAME=$(config-soundcard --no-eeprom --volume-control-softvol)
```

`--volume-control-softvol` returns the card's `volume_control` from
`SOUND_CARD_DEFINITIONS`, falling back to the literal string `"Softvol"`
if no specific value is defined.

If pinning is broken (or the auto-detector misidentifies the card), the
chain looks like this on a Beocreate:

```
real card           = Beocreate 4-Channel Amplifier
SoundcardDetector  -> "DAC+ Light"           (misdetect)
SOUND_CARD_DEFINITIONS["DAC+ Light"].volume_control = None
config-soundcard --volume-control-softvol     -> "Softvol"  (fallback)
librespot --alsa-mixer-control Softvol          -> ENOENT, crash loop
```

With pinning working correctly:

```
ConfigDB.soundcard.name = "Beocreate 4-Channel Amplifier"
SoundcardDetector  -> "Beocreate 4-Channel Amplifier"  (Step 0)
SOUND_CARD_DEFINITIONS[...].volume_control = "DSPVolume"
config-soundcard --volume-control-softvol     -> "DSPVolume"
librespot --alsa-mixer-control DSPVolume      -> works (sigmatcpserver
                                                 owns this control)
```

The dsptoolkit (`hifiberry-dsp`) creates `DSPVolume` independently of any
of this — `sigmatcpserver` registers it on startup. So when `DSPVolume`
seems "missing" from the consumers' point of view, the bug is almost
always in the configurator's pin/detection flow, not in the dsptoolkit.

## Adding a new card

1. Add an entry to `SOUND_CARD_DEFINITIONS` in `configurator/soundcard.py`:
   - `dtoverlay`: the kernel overlay name.
   - `volume_control`: the ALSA mixer control name as exposed by the card
     (or `"DSPVolume"` for DSP-based cards where dsptoolkit owns the
     control).
   - `hat_name`, `aliases`, `output_channels`, `input_channels`, …
2. If detection-by-I2C is needed, add a probe in
   `SoundcardDetector._probe_i2c` and the I2C signature in the
   `i2c_signatures` table near the top of `soundcard_detector.py`.
3. Update tests / fixtures if applicable.
4. Bump `configurator/_version.py` and `debian/changelog`.

## Operator cheat-sheet

```bash
# What does the system think the card is?
config-soundcard                       # full record
config-soundcard --name                 # name only
config-soundcard --volume-control       # mixer for music apps
config-soundcard --json                 # machine-readable

# Inspect the pin
curl -s http://localhost:1081/api/v1/key/soundcard.name
grep -E "HiFiBerry|dtoverlay" /boot/firmware/config.txt

# Pin a card (no reboot needed for userspace; kernel needs reboot)
curl -X POST -H 'Content-Type: application/json' \
  -d '{"card_name":"Beocreate 4-Channel Amplifier"}' \
  http://localhost:1081/api/v1/soundcard/detection/disable

# Drop the pin and let auto-detect run again
curl -X POST http://localhost:1081/api/v1/soundcard/detection/enable

# What ALSA controls does the card actually expose?
amixer -c 0 scontrols
```

# Integrating `analog-recognition` as a HiFiBerryOS plugin

**Date:** 2026-07-06
**Status:** Approved design, pending implementation plan

## Goal

Package `github.com/hifiberry/analog-recognition` for HiFiBerryOS and expose it
as a **player plugin** in the web UI — appearing under "3rd Party Players" with
an enable/disable toggle, exactly like the existing `librespot`, `shairport`,
and `squeezelite` plugins.

`analog-recognition` identifies tracks on the analog (RIAA/turntable) input
using `songrec`, derives real play/stop state from `vu-meter-service`, and
publishes both into AudioControl (acr) as a generic player named `analog`.

Additionally, add a **user-facing setting to enable/disable songrec
recognition**. When recognition is off, the plugin still reports play/stop from
the VU meter but publishes `"Unknown artist"` / `"Unknown song"` instead of
identifying tracks. Because the plugin framework has no way to register a
setting today (only a service on/off toggle), this requires building a
**generic plugin-settings capability** in configurator + the webui, of which
the songrec toggle is the first consumer.

## Background: how the "plugin method" actually works

Investigated against the live device (`matuschd@192.168.11.136`, hostname
`vinyl`) and the existing `hifiberry-squeezelite` package, which is the
canonical working template.

A player plugin is registered entirely from its own **`debian/postinst`**
(and cleaned up in **`postrm`**). The drop-in files are *not* packaged files —
they are written on `configure` and removed on `remove`/`purge`. Three
subsystems each read a drop-in:

1. **Web UI registry** — configurator serves `GET /api/v1/players` from
   `PlayerRegistryHandler`, which scans `/etc/hifiberry/players.d/*.json`
   (required fields: `name`, `provided_by`, `systemd_service`, `icon`;
   optional `allow_change`, `maintainer_name`, `maintainer_url`) and serves
   the icon from `/etc/hifiberry/players.d/icons/<icon>.svg`. The webui view
   `services/players.vue` renders these under "3rd Party Players".

2. **Service toggle permission** — the toggle drives configurator's systemd
   handler, which defaults every service to `status`-only. Enable/disable is
   permitted only if the service is listed at level `all` in the `systemd`
   config section. That section merges drop-ins from
   `/etc/configserver/conf.d/*.json`.

3. **AudioControl backend** — acr merges `/etc/audiocontrol/players.d/*.json`
   into its players list (`merge_player_includes`), a non-clobbering
   alternative to editing `/etc/audiocontrol/audiocontrol.json` directly.

The webui has **no** "available but not installed" catalog and **no**
package-install endpoint. A plugin is visible only when its descriptor exists,
which happens only when the deb is installed. Therefore: to be visible
out-of-the-box, the deb must be in the image.

### Facts established on the device

- pipewire, wireplumber, and every player (mpd, raat, squeezelite, librespot,
  vu-meter) run as **`--user`** services under `matuschd`.
  `/etc/hifiberry.user` = `matuschd`.
- `hifiberry-analog-recognition` 0.1.0 is already installed and its
  `analog-recognition.service` is enabled — as a **user** unit. It currently
  ships only the binary, `config.toml`, and the user unit; **none** of the
  three plugin drop-ins.
- `audiocontrol` and `hifiberry-bluetooth` are the only system-scoped services.
- `librespot`/`shairport`/`squeezelite` register their drop-ins from postinst
  and are visible plugins in the webui.

This corrects two earlier assumptions: the service stays a **user** service
(not converted to system), and the drop-ins live in the upstream repo's
maintainer scripts (not a local overlay, not separately packaged files).

## Scope of changes

Four upstream repos change, each vendored into `hifiberryos-ng` under
`packages/<name>/`:

- **A. `hifiberry/analog-recognition`** — packaging drop-ins + songrec toggle.
- **B. `hifiberryos-ng`** — new `packages/analog-recognition/` build files +
  `hbos-full` meta inclusion.
- **C. `hifiberry/configurator` and `hifiberry/hbos-ui`** — the generic
  plugin-settings framework.

### A. Upstream `hifiberry/analog-recognition` (HiFiBerry-owned)

This is where the core packaging work happens. Changes made and pushed
upstream (it already ships `debian/` + `package-files/`).

**A1. `debian/postinst`** — on `configure`, write the three drop-ins,
mirroring `hifiberry-squeezelite.postinst`:

- `/etc/hifiberry/players.d/analog.json`:
  ```json
  {
      "name": "Analog Input",
      "provided_by": "analog-recognition",
      "systemd_service": "analog-recognition",
      "icon": "analog",
      "allow_change": true,
      "maintainer_name": "HiFiBerry",
      "maintainer_url": "https://github.com/hifiberry/analog-recognition",
      "settings": [
          {
              "key": "songrec_enabled",
              "type": "toggle",
              "label": "Recognize tracks",
              "description": "Identify tracks with songrec. When off, shows \"Unknown artist\" / \"Unknown song\".",
              "default": true
          }
      ]
  }
  ```
  (`maintainer` is HiFiBerry, not "Wanted" — this is a HiFiBerry-owned player,
  unlike the community-maintained squeezelite/librespot/shairport.) The
  `settings` array is the new capability described in section C; the value is
  stored in configurator's ConfigDB under
  `player.analog-recognition.songrec_enabled`.
- copy `/usr/share/hifiberry-analog-recognition/icons/analog.svg` →
  `/etc/hifiberry/players.d/icons/analog.svg`.
- `/etc/configserver/conf.d/analog-recognition.json`:
  ```json
  { "systemd": { "analog-recognition": "all" } }
  ```
- `/etc/audiocontrol/players.d/analog.json` (guarded by `[ -d /etc/audiocontrol ]`):
  ```json
  {
      "generic": {
          "name": "analog",
          "display_name": "Analog Input",
          "enable": true,
          "supports_api_events": true,
          "capabilities": [],
          "initial_state": "stopped"
      }
  }
  ```
  The outer key `generic` is the acr player-type tag (matches how `mpd`, `raat`
  etc. are keyed), not an instance name.

**A2. `debian/postrm`** — on `remove`/`purge`, delete those four files
(descriptor, icon, conf.d, audiocontrol drop-in), mirroring
`hifiberry-squeezelite.postrm`.

**A3. Icon asset** — add `package-files/usr/share/hifiberry-analog-recognition/icons/analog.svg`
(a turntable/analog glyph; created as part of this work — single-colour SVG so
it themes correctly, consistent with the other player icons), and install it in
`debian/rules` `override_dh_auto_install`.

**A4. Service stays a `--user` unit.** No change to scope. The unit remains at
`/usr/lib/systemd/user/analog-recognition.service`, installed via
`dh_installsystemduser`, **auto-enabled on install** (matching squeezelite).

**A5. `debian/control`** — keep `Depends: songrec`; add runtime companions
`hifiberry-audiocontrol` and `hifiberry-vu-meter` (the service publishes to acr
and consumes vu-meter). configurator/webui/baseconfig are not hard deps — the
postinst uses `mkdir -p` and guards, matching squeezelite. Bump changelog to a
new version so the rebuilt deb carries the postinst/postrm.

**A6. `README.md`** — replace the manual "add this to audiocontrol.json"
instruction with the players.d drop-in mechanism (now automatic via postinst),
and note the webui plugin registration and the songrec-enable setting.

**A7. songrec enable/disable behavior (Rust code + config).** The plugin reads
its `songrec_enabled` setting from configurator's ConfigDB and adjusts behavior
live:

- `config.toml` gains a `[configurator]` section (base URL, default
  `http://localhost:1081/api/v1`) and the setting key
  `player.analog-recognition.songrec_enabled`. Static config (device,
  intervals, thresholds) stays in `config.toml`; only the toggleable runtime
  setting lives in ConfigDB.
- On each recognition cycle (already every `request_interval_secs`, ~10s), the
  plugin reads the key via `GET /api/v1/key/<key>`. **Key absent ⇒ default
  `true`** (recognition on). Reading each cycle means a UI toggle takes effect
  within one interval — no service restart.
- When **enabled**: current behavior (run songrec, publish identified
  artist/title).
- When **disabled**: skip songrec entirely; while the VU meter reports playing,
  publish `artist = "Unknown artist"`, `title = "Unknown song"` to acr; play/stop
  state is unaffected.

This keeps the plugin the sole authority on its own behavior; the framework
(section C) only stores and surfaces the value.

### B. This repo (`hifiberryos-ng`)

**B1. `packages/analog-recognition/`** — new package directory, auto-discovered
by `build-all`. Clone-based build tracking `main` HEAD (as agreed):

- `build.sh` — source `../../scripts/cross-compile-env.sh` if present; clone
  `https://github.com/hifiberry/analog-recognition` into `analog-recognition/`
  (or `git pull` if present); `cd` in and
  `sbuild --chroot-mode=unshare --enable-network --no-clean-source`
  (honouring `$DIST`); move `*.deb` back up; prune
  `.build/.changes/.buildinfo/.dsc/.tar.*`; keep only the newest
  `hifiberry-analog-recognition_*.deb`. The upstream repo ships its own
  `debian/`, so **no local debian overlay**.
- `clean.sh` — remove the `analog-recognition/` clone dir and all
  `hifiberry-analog-recognition_*` build artifacts.
- `README.md` — short description pointing at the upstream repo and noting the
  plugin registration.

**B2. `packages/hifiberryos/src/debian/control`** — add
`hifiberry-analog-recognition` to the `hbos-full` `Depends:` list (alongside
`hifiberry-librespot`/`shairport`/`squeezelite`/`raat`), add a matching bullet
to its Description, and bump `debian/changelog`. This makes the plugin present
and visible out-of-the-box in full images.

### C. Plugin-settings framework (new capability — configurator + webui)

The plugin descriptor and webui currently support only a service on/off toggle.
To let a plugin declare configurable settings that render in the UI, add a
generic, schema-driven settings capability. `songrec_enabled` is its first
consumer; the mechanism is reusable by any future plugin.

**C1. Descriptor spec — `settings` array.** Optional. Each entry:

| field | required | notes |
|---|---|---|
| `key` | yes | short id, unique within the plugin (e.g. `songrec_enabled`) |
| `type` | yes | `toggle` (bool) or `select` (enumerated); renderer is extensible |
| `label` | yes | control label |
| `description` | no | help text |
| `default` | yes | value used when nothing is stored |
| `options` | select only | list of `{value,label}` |

MVP renders `toggle` (this feature) and `select` (mirrors the existing
Airplay/TOSLink dropdowns). Storage is per-plugin-namespaced in ConfigDB under
`player.<systemd_service>.<key>` (values are stored as TEXT; booleans as
`"true"`/`"false"`).

**C2. configurator — `PlayerRegistryHandler`.**
- `handle_list_players` (`GET /api/v1/players`) includes each descriptor's
  `settings`, and enriches every setting with its **current `value`** read from
  ConfigDB (`player.<service>.<key>`, coerced by `type`, falling back to
  `default`). One call gives the webui schema + current state.
- New write endpoint `PUT /api/v1/players/<systemd_service>/settings`, body
  `{ "<key>": <value>, ... }`. Validates each key against the descriptor's
  declared settings, coerces by `type`, and writes to
  `player.<service>.<key>` in ConfigDB. Server-side namespacing keeps the webui
  from constructing raw keys. Registered in `server.py` alongside the existing
  `/api/v1/players` routes.

**C3. webui.**
- `ExternalPlayer` type (`api/config.ts`) gains
  `settings?: PlayerSetting[]` where `PlayerSetting` carries
  `key,type,label,description?,default,value,options?`. Add
  `saveExternalPlayerSettings(systemdService, values)` calling the C2 PUT.
- `services/players.vue` `Player` interface carries `settings`; the
  external-player merge copies them through. `saveConfig` branches for external
  players → `saveExternalPlayerSettings` → refresh.
- `PlayerCard.vue`: `hasConfig` also returns true when
  `player.isExternal && (player.settings?.length ?? 0) > 0`. Add a **generic**
  config section that `v-for`s over `player.settings` and renders a control per
  `type` (`toggle` → switch, `select` → dropdown), bound to a local editable
  copy, with the existing Save/Cancel actions. The bespoke Airplay/TOSLink
  blocks are left untouched.

**Boundary check:** the framework never knows about songrec specifically — it
stores/serves opaque key/value settings declared by descriptors. The plugin is
the only component that interprets `songrec_enabled`. A future plugin adds a
setting purely by extending its own descriptor.

## Data flow (runtime)

```
turntable/RIAA in ──▶ pipewire (riaa.monitor)
                          │
        ┌─────────────────┴───────────────────┐
        ▼                                      ▼
   vu-meter-service (level)            songrec (recognition)
        │                                      │
        └──────────────▶ analog-recognition ◀──┘
                                │  publishes generic player "analog"
                                ▼
                          AudioControl (acr)
                                ▲
        registered via /etc/audiocontrol/players.d/analog.json

Web UI  ── GET /api/v1/players ──▶ configurator ── scans /etc/hifiberry/players.d
           (returns descriptor + settings schema + current values)
Toggle  ── POST systemd/service/analog-recognition/enable-now ──▶ configurator
           (permitted by /etc/configserver/conf.d/analog-recognition.json)

Setting "Recognize tracks":
Web UI  ── PUT /api/v1/players/analog-recognition/settings {songrec_enabled} ──▶
           configurator ── writes ConfigDB key player.analog-recognition.songrec_enabled
analog-recognition ── GET /api/v1/key/player.analog-recognition.songrec_enabled
           (each cycle) ──▶ recognize, or publish "Unknown artist"/"Unknown song"
```

## Decisions (locked)

| Decision | Choice | Rationale |
|---|---|---|
| Build style | Clone-based, tracks `main` HEAD | Matches riaa; self-contained, no submodule wiring |
| Service scope | `--user` service (unchanged) | Device evidence: all players + pipewire are user-scoped |
| Drop-in home | Upstream `debian/postinst`/`postrm` | Canonical pattern (squeezelite); no local overlay |
| Enable on install | Auto-enable (match squeezelite) | Consistency with existing player plugins |
| Image inclusion | Add to `hbos-full` | Required for UI visibility; matches other player plugins |
| songrec toggle UI | Generic plugin-settings framework | Reusable by all plugins; avoids special-casing in generic UI |
| Settings storage | configurator ConfigDB, `player.<service>.<key>` | Existing key/value store; plugin reads via HTTP, no restart |
| Setting read cadence | Plugin polls each recognition cycle (~10s) | Live toggle without a service restart |

## Consequence to note

Auto-enable + inclusion in `hbos-full` means every full-image device runs
analog-input recognition by default whenever signal is present. songrec sends
audio fingerprints to Shazam's servers to identify tracks — an outbound data
flow that is on by default under these two combined choices. Flagged for
awareness; not blocking. (The user can still disable it via the webui toggle.)

## Verification plan

Exercised on `matuschd@192.168.11.136`:

1. Build the deb via `packages/analog-recognition/build.sh`; install it.
2. `dpkg -L` shows the icon under `/usr/share/hifiberry-analog-recognition/icons/`.
3. After install, the four drop-ins exist:
   `/etc/hifiberry/players.d/analog.json` (+ `icons/analog.svg`),
   `/etc/configserver/conf.d/analog-recognition.json`,
   `/etc/audiocontrol/players.d/analog.json`.
4. `curl -s localhost:1081/api/v1/players` returns the `analog` entry with
   `allow_change: true` and a `settings` array whose `songrec_enabled` carries
   its current value (default `true`).
5. The webui "Players" view shows "Analog Input" under 3rd Party Players with a
   working toggle; toggling drives `analog-recognition.service` (user scope).
6. acr picks up the generic `analog` player; recognition + play/stop state
   publish correctly against a real signal on `riaa.monitor`.
7. Expanding the plugin's config shows the "Recognize tracks" toggle. Turning it
   **off** and Saving writes `player.analog-recognition.songrec_enabled=false`
   (verify via `GET /api/v1/key/...`); within one cycle the plugin publishes
   `"Unknown artist"` / `"Unknown song"` while play/stop still tracks the VU
   meter. Turning it back **on** restores recognition — no service restart.
8. `apt purge` removes all four drop-ins (postrm).

## Build sequence

The framework (C) is independent of and precedes the plugin's consumption of
it. Suggested order, each independently testable:

1. **C — plugin-settings framework** (configurator + webui): descriptor
   `settings` pass-through, ConfigDB-backed value read/write endpoint, generic
   PlayerCard rendering. Test with a throwaway descriptor before analog exists.
2. **A — upstream analog-recognition**: postinst/postrm drop-ins (incl. the
   `settings` descriptor), icon, songrec-enable behavior + ConfigDB read,
   control/README updates.
3. **B — this repo**: `packages/analog-recognition/` build files + `hbos-full`
   inclusion.

This decomposes cleanly into two implementation plans if preferred: (1) the
framework, (2) the plugin + packaging.

## Out of scope

- No conversion to a system service.
- No changes to **acr** source — its `players.d` mechanism already supports the
  drop-in. (configurator and the webui *are* changed, for the settings
  framework — section C.)
- Settings framework MVP renders `toggle` and `select` only; richer control
  types (sliders, free text with validation, grouped settings) are future work.
- No new "available plugins" catalog or in-UI package installer.
- Publishing to debianrepo.hifiberry.com is a follow-up per the existing
  `copy-packages` / `aptly-publish-public` process, not part of this design.

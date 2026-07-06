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

Two repositories change.

### A. Upstream `hifiberry/analog-recognition` (HiFiBerry-owned)

This is where the real integration work happens. Changes made and pushed
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
      "maintainer_url": "https://github.com/hifiberry/analog-recognition"
  }
  ```
  (`maintainer` is HiFiBerry, not "Wanted" — this is a HiFiBerry-owned player,
  unlike the community-maintained squeezelite/librespot/shairport.)
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
and note the webui plugin registration.

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
Toggle  ── POST systemd/service/analog-recognition/enable-now ──▶ configurator
           (permitted by /etc/configserver/conf.d/analog-recognition.json)
```

## Decisions (locked)

| Decision | Choice | Rationale |
|---|---|---|
| Build style | Clone-based, tracks `main` HEAD | Matches riaa; self-contained, no submodule wiring |
| Service scope | `--user` service (unchanged) | Device evidence: all players + pipewire are user-scoped |
| Drop-in home | Upstream `debian/postinst`/`postrm` | Canonical pattern (squeezelite); no local overlay |
| Enable on install | Auto-enable (match squeezelite) | Consistency with existing player plugins |
| Image inclusion | Add to `hbos-full` | Required for UI visibility; matches other player plugins |

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
   `allow_change: true`.
5. The webui "Players" view shows "Analog Input" under 3rd Party Players with a
   working toggle; toggling drives `analog-recognition.service` (user scope).
6. acr picks up the generic `analog` player; recognition + play/stop state
   publish correctly against a real signal on `riaa.monitor`.
7. `apt purge` removes all four drop-ins (postrm).

## Out of scope

- No conversion to a system service.
- No changes to configurator, acr, or webui source (their mechanisms already
  support this; we only add drop-ins that they read).
- No new "available plugins" catalog or in-UI package installer.
- Publishing to debianrepo.hifiberry.com is a follow-up per the existing
  `copy-packages` / `aptly-publish-public` process, not part of this design.

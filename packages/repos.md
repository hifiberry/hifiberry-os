# External Repositories in `packages/`

Each package that contains source code from an external git repository is listed here.
These are **not** git submodules — they are independently cloned repos checked out
inside the `packages/` directory. The build scripts (`build.sh`) clone them automatically
if the directory doesn't exist; this file documents where they live and which branch to use.

To push changes across all repos, use:
```bash
python3 scripts/git-repo-sync.py --root /home/matuschd/hifiberry-os --include-dirty --push
```

| Package dir | Repo | Branch | Notes |
|-------------|------|--------|-------|
| `packages/acr/acr` | https://github.com/hifiberry/acr | `main` | AudioControl Rust (ACR) — core audio routing service |
| `packages/analog-recognition/analog-recognition` | https://github.com/hifiberry/analog-recognition | `main` | Analog-input song recognition (songrec) plus VU-meter play/stop state, published to ACR as the `analog` player |
| `packages/autorec/autorec` | https://github.com/hifiberry/autorec | `main` | Auto-recording service |
| `packages/bluetooth-service/hbos-bluetooth` | https://github.com/hifiberry/hbos-bluetooth | `main` | Bluetooth audio service |
| `packages/configurator/configurator` | https://github.com/hifiberry/configurator | `main` | System configuration API (Python) |
| `packages/dspprofiles/dspprofiles` | https://github.com/hifiberry/dspprofiles | `master` | DSP profile definitions |
| `packages/dsptoolkit/hifiberry-dsp` | https://github.com/hifiberry/hifiberry-dsp | `master` | DSP management toolkit |
| `packages/hifiberry-auth/hifiberry-auth` | https://github.com/hifiberry/hifiberry-auth | `main` | System-wide authentication gateway (nginx `auth_request` backend) |
| `packages/nowplaying-sdl/nowplaying-sdl` | https://github.com/hifiberry/nowplaying-sdl | `main` | Now-playing SDL display |
| `packages/pw-api/pipewire-api` | https://github.com/hifiberry/pipewire-api | `master` | PipeWire API wrapper (C/Rust) |
| `packages/python-pyedbglib/pyedbglib` | https://github.com/microchip-pic-avr-tools/pyedbglib | `main` | Third-party: Microchip debug library |
| `packages/python-usagecollector/usagecollector` | https://github.com/hifiberry/usagecollector | `master` | Usage/telemetry collector |
| `packages/raat/src/raat` | https://github.com/hifiberry/raat | `master` | RAAT (Roon) player — **private repository**, building it needs credentials that can read it |
| `packages/input-processor/input-processor` | https://github.com/hifiberry/input-processor | `main` | Analog input processor, optional RIAA phono EQ |
| `packages/roomeq/roomeq` | https://github.com/hifiberry/roomeq | `main` | Room equalization |
| `packages/sendspin/sendspin` | https://github.com/hifiberry/sendspin | `main` | Sendspin / Music Assistant player (`sendspind`, C++) |
| `packages/songrec/songrec` | https://github.com/marin-m/SongRec | — | Third-party: song recognition (pinned release, DETACHED HEAD) |
| `packages/speakereq/speakereq` | https://github.com/hifiberry/speakereq | `main` | Speaker equalization |
| `packages/tidal-connect` | https://github.com/pulpier/tidal-connect-hifiberry | `master` | Third-party: Tidal Connect |
| `packages/vu-meter/src` | https://github.com/hifiberry/vu-meter | `main` | VU meter service |
| `packages/webui/hbos-ui` | https://github.com/hifiberry/hbos-ui | `dev` | Web UI (Vue/TypeScript) |

## Build staging directories

The ACR build script creates versioned copies of the source tree (e.g.
`packages/acr/hifiberry-audiocontrol-0.7.12/`) as staging areas for `dpkg-buildpackage`.
These are build artifacts — do **not** push from them directly; always push from
`packages/acr/acr`.

## Adding a new external repo

1. Clone into the appropriate `packages/<name>/` subdirectory
2. Add an entry to this file
3. Update `packages/<name>/build.sh` to clone from the URL if the directory is missing

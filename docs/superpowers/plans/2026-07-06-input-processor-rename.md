# RIAA → Input-Processor Rename Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebrand the analog-input pipewire node from `riaa` to a generic `input-processor`, with RIAA equalization demoted to an optional, off-by-default, mostly-hidden feature — because the common source is line-level (CD player, streamer line-out, turntable *with* preamp), and only the rare bare-turntable case needs RIAA.

**Architecture:** A coordinated "clean break" across five repos. The pipewire node/config, its Debian package, the pw-api control module, and the analog-recognition consumer all rename `riaa` → `input-processor` together and bump versions in lockstep; the RIAA LADSPA plugin's compiled default flips to *disabled*. The RIAA filter stays inside the input-processor node as a bypassed stage that can be enabled via the API.

**Tech Stack:** C (LADSPA plugin), PipeWire/WirePlumber config, Rust (pw-api, analog-recognition), Debian packaging (debhelper 13, sbuild), the HiFiBerryOS aptly repo.

## Global Constraints

- **Node name:** the pipewire virtual node renames `riaa` → `input-processor`; its monitor is `input-processor.monitor`, its passive output `input-processor.output`. The wireplumber autoconnect target and pw-api link-rules follow.
- **Full rename (per decision):** the Debian package renames `ladspa-riaa` → `hifiberry-input-processor`; the pw-api module/route renames `/api/v1/module/riaa` → `/api/v1/module/input-processor`; Rust types `Riaa*` → `InputProcessor*`; the pw-cli param-key prefix renames `riaa:` → `input-processor:`. The LADSPA **port labels** (`"RIAA Enable"`, `"Gain (dB)"`, …) and the **plugin `.so`/label** (`riaa.so`, LADSPA label `riaa`, UniqueID 6839) stay — they are the RIAA filter's identity, not the node identity.
- **RIAA off by default:** the LADSPA plugin's compiled default for the `RIAA Enable` port flips to disabled (`riaa_ladspa.c:143` `1.0f`→`0.0f`; `:622` `LADSPA_HINT_DEFAULT_1`→`LADSPA_HINT_DEFAULT_0`). The pipewire conf also sets `"RIAA Enable" = 0` explicitly.
- **Recognition uses the raw signal:** analog-recognition/songrec taps `input-processor.monitor` and does NOT enable RIAA — for line-level sources the raw signal is already correct.
- **Clean break, no compat alias:** the package rename carries `Conflicts`/`Replaces`/`Provides: ladspa-riaa` so upgrades swap atomically. Existing `riaa`-named references stop working after upgrade; all five packages publish together.
- **Delivery: commit directly to each repo's `main` branch and push. Do NOT open PRs.** After all repos are pushed, build + publish all packages together, then verify on device `192.168.11.136`.
- Repos: `hifiberry/riaa` (→ package `hifiberry-input-processor`), `hifiberry/pipewire-api`, `hifiberry/analog-recognition`, `hifiberry/pipewire-configs`, and the OS repo `hifiberryos-ng`.
- Build host: `192.168.1.112` (`~/hifiberry-os`); publish via `~/hifiberry-os/packages/copy-packages` (`yes y`) then `ssh matuschd@192.168.1.112 'bash -lc aptly-publish-public'`.
- Never add `Co-Authored-By` lines to commits.

## Repos & where each is edited

Work in fresh clones under `/Users/matuschd/localdev/`:
- `riaa/` = `git clone https://github.com/hifiberry/riaa`
- `pipewire-api/` = `git clone https://github.com/hifiberry/pipewire-api`
- `analog-recognition/` = already cloned at `/Users/matuschd/localdev/analog-recognition`
- `pipewire-configs/` = `git clone https://github.com/hifiberry/pipewire-configs`
- OS repo edits are in `/Users/matuschd/localdev/hifiberryos-ng` (branch `hbosng`).

---

## Phase A — `hifiberry/riaa` → package `hifiberry-input-processor`

### Task A1: Flip the LADSPA RIAA-enable default to OFF

**Files:**
- Modify: `riaa_ladspa.c:143` and `riaa_ladspa.c:620-622`

**Interfaces:**
- Produces: the built `riaa.so` now defaults `RIAA Enable` to 0 (bypass) both via the LADSPA host hint and the config-file fallback.

- [ ] **Step 1: Change the config-file fallback default**

In `riaa_ladspa.c` line 143, change:
```c
        plugin->default_riaa_enable = config_get_float(&config, RIAA_PORT_NAME_ENABLE, 1.0f);
```
to:
```c
        plugin->default_riaa_enable = config_get_float(&config, RIAA_PORT_NAME_ENABLE, 0.0f);
```

- [ ] **Step 2: Change the LADSPA host-hint default**

In `riaa_ladspa.c` around line 620-622, change the `RIAA_ENABLE` hint:
```c
            port_range_hints[RIAA_ENABLE].HintDescriptor =
                LADSPA_HINT_TOGGLED |
                LADSPA_HINT_DEFAULT_1;
```
to:
```c
            port_range_hints[RIAA_ENABLE].HintDescriptor =
                LADSPA_HINT_TOGGLED |
                LADSPA_HINT_DEFAULT_0;
```

- [ ] **Step 3: Build and smoke-test the default**

Run: `make clean && make ladspa riaa_process`
Expected: compiles, produces `riaa.so`. There is an existing test harness `test-plugin.py` (`TEST-PLUGIN.md` documents it) — run `python3 test-plugin.py` if present and confirm no regressions in the passthrough path. If no automated default-check exists, confirm by inspection that both defaults now read `0`.

- [ ] **Step 4: Commit**

```bash
git add riaa_ladspa.c
git commit -m "plugin: default RIAA Enable to off (bypass) — line-level is the common case"
```

---

### Task A2: Rename the pipewire node config `riaa` → `input-processor`

**Files:**
- Rename+modify: `pipewire/90-riaa.conf` → `pipewire/90-input-processor.conf`
- Rename+modify: `pipewire/99-riaa-autoconnect.conf` → `pipewire/99-input-processor-autoconnect.conf`

**Interfaces:**
- Produces: a pipewire node named `input-processor` (Audio/Sink → `input-processor.monitor`), passive output `input-processor.output`; wireplumber autoconnect from the ALSA analog capture to target `input-processor`. The filter-graph node name becomes `input-processor` (this is the pw-cli Props param-key prefix). The RIAA filter stays (label `riaa`, `.so` unchanged) but is bypassed by default.

- [ ] **Step 1: Rename and rewrite `90-input-processor.conf`**

```bash
git mv pipewire/90-riaa.conf pipewire/90-input-processor.conf
```
In `pipewire/90-input-processor.conf` apply these exact changes:
- `node.description = "RIAA Phono Preamp"` → `node.description = "Analog Input Processor"`
- `media.name = "RIAA Phono Preamp"` → `media.name = "Analog Input Processor"`
- the filter-graph node `name = riaa` → `name = "input-processor"` (this becomes the param-key prefix; keep `label = riaa` and `plugin = /usr/lib/ladspa/riaa.so` unchanged — that is the RIAA plugin identity)
- in the `control = { … }` block, replace the commented-out `# "RIAA Enable" = 1` with an active `"RIAA Enable" = 0` (explicit bypass at load, belt-and-braces with the plugin default)
- `capture.props { node.name = "riaa" … }` → `node.name = "input-processor"`
- `playback.props { node.name = "riaa.output" … }` → `node.name = "input-processor.output"`

- [ ] **Step 2: Rename and rewrite the autoconnect config**

```bash
git mv pipewire/99-riaa-autoconnect.conf pipewire/99-input-processor-autoconnect.conf
```
In it, change the link rule `target = "riaa"` → `target = "input-processor"`. Leave the source match `node.name = "~alsa_input.platform-soc_.*"` unchanged. Update the header comment wording from "RIAA Phono Preamp" to "Analog Input Processor".

- [ ] **Step 3: Validate the conf is well-formed SPA-JSON**

Run: `pipewire -c pipewire/90-input-processor.conf --version 2>/dev/null; echo checked` — if pipewire isn't available locally, instead confirm balanced braces and that the only remaining bare `riaa` tokens are `label = riaa` and the `.so` path:
`grep -nE '\briaa\b' pipewire/90-input-processor.conf` → expect only the `label = riaa` and `plugin = …/riaa.so` lines.

- [ ] **Step 4: Commit**

```bash
git add pipewire/90-input-processor.conf pipewire/99-input-processor-autoconnect.conf
git commit -m "pipewire: rename node riaa -> input-processor; RIAA bypassed by default"
```

---

### Task A3: Rename the Debian package `ladspa-riaa` → `hifiberry-input-processor`

**Files:**
- Modify: `debian/control`
- Modify: `debian/rules`
- Modify: `debian/changelog`

**Interfaces:**
- Produces: a deb named `hifiberry-input-processor` that `Provides`/`Replaces`/`Conflicts` `ladspa-riaa`, installs `riaa.so` (unchanged path), the renamed pipewire confs, and `riaa_process`.

- [ ] **Step 1: Rewrite `debian/control`**

Change `Source: ladspa-riaa` → `Source: hifiberry-input-processor`. Change the binary stanza `Package: ladspa-riaa` → `Package: hifiberry-input-processor`, and add these fields to that stanza:
```
Provides: ladspa-riaa
Replaces: ladspa-riaa
Conflicts: ladspa-riaa
```
Update the `Description:` first line to `Analog input processor (line-level) with optional RIAA phono equalization`. Keep `Build-Depends`, `Depends`, `Homepage`, `Vcs-*` as-is.

- [ ] **Step 2: Rewrite `debian/rules` install paths**

Replace every `debian/ladspa-riaa/` path with `debian/hifiberry-input-processor/`, and update the two conf install lines to the new filenames:
```make
	install -m 644 pipewire/90-input-processor.conf $(CURDIR)/debian/hifiberry-input-processor/etc/pipewire/pipewire.conf.d/
	install -m 644 pipewire/99-input-processor-autoconnect.conf $(CURDIR)/debian/hifiberry-input-processor/etc/xdg/wireplumber/wireplumber.conf.d/
```
Update the doc-dir path `usr/share/doc/ladspa-riaa` → `usr/share/doc/hifiberry-input-processor`. Keep `install-ladspa` (the `.so` still lands at `/usr/lib/ladspa/riaa.so`).

- [ ] **Step 3: Add a changelog entry with the new source name**

Prepend to `debian/changelog` a new top entry using the source name `hifiberry-input-processor` and a fresh version (start at the current version's next patch, or `1.3.0` if renaming warrants a minor bump — read the current top line first and increment):
```
hifiberry-input-processor (<version>) stable; urgency=medium

  * Rename package ladspa-riaa -> hifiberry-input-processor (Provides/Replaces/
    Conflicts the old name for a clean upgrade).
  * Rename the pipewire node riaa -> input-processor (input-processor.monitor /
    .output); wireplumber autoconnect target updated.
  * RIAA equalization is now OFF by default (line-level input is the common
    case); it remains available as an optional, bypassable filter stage.

 -- HiFiBerry <support@hifiberry.com>  <RFC2822 date>
```
Use `date -R` for the date.

- [ ] **Step 4: Verify changelog parses**

Run: `dpkg-parsechangelog >/dev/null && echo OK` (from the repo root). If `dpkg-parsechangelog` is unavailable, verify the header/footer format matches the entry below it exactly (two spaces before the date).

- [ ] **Step 5: Commit and push `main`**

```bash
git add debian/control debian/rules debian/changelog
git commit -m "debian: rename package ladspa-riaa -> hifiberry-input-processor (Provides/Replaces/Conflicts)"
git push origin main
```

---

## Phase B — `hifiberry/pipewire-api`

### Task B1: Rename the pw-api node + module `riaa` → `input-processor`

**Files:**
- Modify: `src/pipewire-api.rs` (NodeState line + module wiring)
- Rename+modify: `src/riaa.rs` → `src/input_processor.rs`
- Modify: `src/settings.rs`, `src/graph.rs`, `link-rules.conf`
- Modify: `src/lib.rs` (module export), `Cargo.toml` unaffected
- Modify: `tests/test_riaa_api.py` (rename → `tests/test_input_processor_api.py`)
- Modify: `debian/changelog`

**Interfaces:**
- Consumes: the pipewire node `input-processor` and its `input-processor.output` port (from Task A2); pw-cli Props keyed by `input-processor:<port>`.
- Produces: HTTP routes under `/api/v1/module/input-processor/*` (config, gain, subsonic, riaa-enable, declick, spike, notch, set-default, save); Rust `InputProcessorConfig`, `input_processor::create_router`.

- [ ] **Step 1: Rename the node lookup + module wiring in `pipewire-api.rs`**

At `src/pipewire-api.rs:119`, change:
```rust
    let riaa_state = Arc::new(NodeState::new("riaa".to_string()));
```
to:
```rust
    let input_processor_state = Arc::new(NodeState::new("input-processor".to_string()));
```
and update the two uses below it: `pw_api::riaa::create_router(riaa_state.clone())` → `pw_api::input_processor::create_router(input_processor_state.clone())`, and in `pw_api::settings::create_router(speakereq_state, riaa_state, Some(10))` → `…, input_processor_state, Some(10))`.

- [ ] **Step 2: Rename the module file and its symbols**

```bash
git mv src/riaa.rs src/input_processor.rs
```
In `src/input_processor.rs`, apply a scoped rename:
- route base `/module/riaa` → `/module/input-processor`
- struct `RiaaConfig` → `InputProcessorConfig` (keep its JSON field names `gain_db`, `subsonic_filter`, `riaa_enable`, `declick_enable`, `spike_threshold_db`, `spike_width_ms`, `notch_filter_enable`, `notch_frequency_hz`, `notch_q_factor` — they map to the LADSPA ports and stay RIAA-named)
- every pw-cli param key prefix `"riaa:` → `"input-processor:` (e.g. `"riaa:Gain (dB)"` → `"input-processor:Gain (dB)"`; there are ~40) — keep the port-label suffixes verbatim (`RIAA Enable`, `Gain (dB)`, `Store settings`, etc.)
- function names `get_riaa_enable`/`set_riaa_enable` etc. may stay (they describe the RIAA control) OR rename for consistency; keep `create_router` public.
- In `src/lib.rs`, change `pub mod riaa;` → `pub mod input_processor;`.

- [ ] **Step 3: Update `settings.rs`, `graph.rs`, `link-rules.conf`**

- `src/settings.rs`: the `riaa: Option<RiaaConfig>` field type → `Option<InputProcessorConfig>` (rename the import); the `"riaa:…"` param keys in restore → `"input-processor:…"`. Keep the JSON key `riaa` in the persisted `Settings` struct only if you want backward-compatible settings files — per the clean-break decision, rename it to `input_processor` too.
- `src/graph.rs:64`: `name_lower.contains("riaa")` → `name_lower.contains("input-processor")`.
- `link-rules.conf`: rule 1 destination `"node.name": "^riaa$"` → `"^input-processor$"`; rule 2 source `"node.name": "^riaa\\.output$"` → `"^input-processor\\.output$"`. Also update the rule `name` strings ("Analog input to RIAA Filter" → "Analog input to Input Processor", "RIAA Output to SpeakerEQ" → "Input Processor Output to SpeakerEQ"). Leave the speakereq rules unchanged.

- [ ] **Step 4: Update the test file**

```bash
git mv tests/test_riaa_api.py tests/test_input_processor_api.py
```
In it, change the node-name discovery `obj.get("name") == "riaa"` → `== "input-processor"` and the base path `/module/riaa` → `/module/input-processor`. Keep RIAA-specific param assertions (`riaa_enable`, port labels).

- [ ] **Step 5: Build and test**

Run: `source "$HOME/.cargo/env" && cargo build && cargo test`
Expected: compiles clean; unit tests pass. (`tests/test_input_processor_api.py` is an integration test needing a live pipewire node — it is exercised on-device in Phase F, not here.)

- [ ] **Step 6: Changelog, commit, push `main`**

Prepend a `pipewire-api (<next version>)` changelog entry describing the node/module/route rename `riaa` → `input-processor`. Then:
```bash
git add -A
git commit -m "api: rename node/module/route riaa -> input-processor"
git push origin main
```

---

## Phase C — `hifiberry/analog-recognition`

### Task C1: Point songrec at `input-processor.monitor`

**Files:**
- Modify: `package-files/etc/analog-recognition/config.toml`
- Modify: `src/config.rs` (default + tests at lines 106, 122, 135, 158, 186)
- Modify: `debian/changelog`

**Interfaces:**
- Consumes: the `input-processor.monitor` pipewire source (from Task A2).
- Produces: shipped default `[songrec] device = "input-processor.monitor"`.

- [ ] **Step 1: Update the shipped config default**

In `package-files/etc/analog-recognition/config.toml`, change `device = "riaa.monitor"` → `device = "input-processor.monitor"` in the `[songrec]` section.

- [ ] **Step 2: Update the Rust defaults + tests**

In `src/config.rs`, replace every `"riaa.monitor"` with `"input-processor.monitor"` (the default value and the test fixtures at the lines noted). Run `source "$HOME/.cargo/env" && cargo test --lib config::` and confirm the config tests still pass with the new expected string.

- [ ] **Step 3: Changelog, commit, push `main`**

Prepend a changelog entry (bump the version) noting the songrec device rename `riaa.monitor` → `input-processor.monitor`. Then:
```bash
git add -A
git commit -m "songrec: capture from input-processor.monitor (was riaa.monitor)"
git push origin main
```

---

## Phase D — `hifiberry/pipewire-configs`

### Task D1: Depend on the renamed package

**Files:**
- Modify: `debian/control` (Depends line)
- Modify: `debian/changelog`

**Interfaces:**
- Produces: `hifiberry-pipewire-configs` now `Depends` on `hifiberry-input-processor` instead of `ladspa-riaa`, keeping the default-install chain intact.

- [ ] **Step 1: Update the Depends**

In `debian/control`, change:
```
Depends: ${misc:Depends}, pipewire, ladspa-riaa, ladspa-speakereq, pipewire-api
```
to:
```
Depends: ${misc:Depends}, pipewire, hifiberry-input-processor, ladspa-speakereq, pipewire-api
```

- [ ] **Step 2: Changelog, commit, push `main`**

Prepend a changelog entry (bump version): "Depend on hifiberry-input-processor (renamed from ladspa-riaa)." Then:
```bash
git add debian/control debian/changelog
git commit -m "control: depend on hifiberry-input-processor (was ladspa-riaa)"
git push origin main
```

---

## Phase E — `hifiberryos-ng` build wiring

### Task E1: Update the OS repo's riaa package build to the new deb name

**Files (in `/Users/matuschd/localdev/hifiberryos-ng`, branch `hbosng`):**
- Modify: `packages/riaa/build.sh`
- Modify: `packages/riaa/clean.sh`

**Interfaces:**
- Produces: `packages/riaa/build.sh` builds and keeps `hifiberry-input-processor_*.deb` (the OS build clones the same `hifiberry/riaa` repo, which now produces the renamed deb).

- [ ] **Step 1: Update the deb name in build.sh/clean.sh**

In `packages/riaa/build.sh`, change `DEB_PACKAGE="ladspa-riaa"` → `DEB_PACKAGE="hifiberry-input-processor"`. In `packages/riaa/clean.sh`, update any `ladspa-riaa*` artifact globs to `hifiberry-input-processor*` (and keep removing the old `ladspa-riaa*.deb` so stale debs don't linger). The `REPO_URL` (`https://github.com/hifiberry/riaa`) and `PACKAGE="riaa"` clone dir stay the same.

- [ ] **Step 2: Commit (do not push yet — batch with the meta if needed)**

```bash
git add packages/riaa/build.sh packages/riaa/clean.sh
git commit -m "build(riaa): produce hifiberry-input-processor deb (renamed from ladspa-riaa)"
```

Note: the `hbos-full`/`hbos-minimal` meta packages do NOT list `ladspa-riaa` (it's pulled transitively via `hifiberry-pipewire-configs`), so no meta-control change is needed. Push `hbosng` when convenient: `git push origin hbosng`.

---

## Phase F — Coordinated build, publish, and on-device verification

This phase must run after Phases A–E are pushed. All commands on the build host `192.168.1.112` unless noted.

- [ ] **Step 1: Pull and build all affected packages**

On the build host, in `~/hifiberry-os`:
```bash
git -C ~/hifiberry-os pull --ff-only     # picks up packages/riaa build.sh change
for p in riaa pipewire-configs pw-api analog-recognition; do
  ( cd ~/hifiberry-os/packages/$p && ./build.sh )
done
```
Expected: `packages/riaa/` now yields `hifiberry-input-processor_*.deb` (verify with `ls`), plus rebuilt `hifiberry-pipewire-configs`, `pipewire-api`, `hifiberry-analog-recognition`. Confirm the old `ladspa-riaa_*.deb` is gone from `packages/riaa/`.

- [ ] **Step 2: Sanity-check the renamed deb**

```bash
dpkg -I ~/hifiberry-os/packages/riaa/hifiberry-input-processor_*.deb | grep -iE "Package|Provides|Replaces|Conflicts"
dpkg -c ~/hifiberry-os/packages/riaa/hifiberry-input-processor_*.deb | grep -E "input-processor.conf|input-processor-autoconnect.conf|ladspa/riaa.so"
```
Expected: `Package: hifiberry-input-processor`, the three `Provides/Replaces/Conflicts: ladspa-riaa`, both renamed confs present, and `riaa.so` still at `/usr/lib/ladspa/`.

- [ ] **Step 3: Publish all**

```bash
cd ~/hifiberry-os/packages && yes y | ./copy-packages
ssh matuschd@192.168.1.112 'bash -lc aptly-publish-public'   # or run bash -lc aptly-publish-public directly on host
```
Expected: `hifiberry-input-processor`, `hifiberry-pipewire-configs`, `pipewire-api`, `hifiberry-analog-recognition` (new versions) added and rsynced.

- [ ] **Step 4: Upgrade the device and verify the swap**

On `192.168.11.136`:
```bash
sudo apt-get update
sudo apt-get install -y hifiberry-input-processor hifiberry-pipewire-configs pipewire-api hifiberry-analog-recognition
dpkg -l ladspa-riaa 2>/dev/null || echo "ladspa-riaa removed (replaced) — good"
dpkg -l hifiberry-input-processor | grep ^ii
```
Expected: `hifiberry-input-processor` installed; `ladspa-riaa` gone (Replaced/Conflicted out).

- [ ] **Step 5: Verify the pipewire node + RIAA default + param prefix**

On the device, in the user session (`export XDG_RUNTIME_DIR=/run/user/$(id -u)`):
```bash
systemctl --user restart pipewire wireplumber; sleep 3
pw-cli ls Node | grep -iE "input-processor"      # expect a node named input-processor
pw-cli ls Node | grep -i riaa                    # expect NO bare 'riaa' node
ID=$(pw-cli ls Node | awk '/input-processor/{print prev} {prev=$0}' | head -1)  # or find the id manually
pw-cli enum-params <input-processor-node-id> Props | grep -iE "input-processor:RIAA Enable"
```
Expected: a node named `input-processor` exists, no `riaa` node; the Props param keys are prefixed `input-processor:` and `RIAA Enable` reads `0`/false (bypassed by default). **This is the key check that confirms the param-key prefix followed the node rename** — if the keys are still prefixed differently, adjust the filter-graph node name in `90-input-processor.conf` accordingly.

- [ ] **Step 6: Verify the pw-api route and recognition**

```bash
curl -s http://localhost:2716/api/v1/module/input-processor/config    # expect the config JSON, riaa_enable=false
curl -s http://localhost:2716/api/v1/module/riaa/config; echo " <- expect 404 (old route gone)"
# recognition:
export XDG_RUNTIME_DIR=/run/user/$(id -u)
pgrep -a songrec    # expect: songrec listen -d input-processor.monitor ...
```
Expected: the new `/module/input-processor` route works and reports `riaa_enable: false`; the old `/module/riaa` route is gone; songrec captures from `input-processor.monitor`. Confirm the Analog Input plugin still recognizes/reports state (drive a signal into the analog input and confirm songrec output, or confirm the analog-recognition service is `active` and songrec running).

- [ ] **Step 7: Enable RIAA once to prove the optional path still works**

```bash
curl -s -X PUT -H 'Content-Type: application/json' -d 'true' http://localhost:2716/api/v1/module/input-processor/riaa-enable
pw-cli enum-params <input-processor-node-id> Props | grep -i "RIAA Enable"   # expect 1/true now
# then restore off:
curl -s -X PUT -H 'Content-Type: application/json' -d 'false' http://localhost:2716/api/v1/module/input-processor/riaa-enable
```
Expected: the RIAA stage toggles on/off via the API — proving RIAA is preserved as an optional, off-by-default feature.

---

## Out of scope (noted, not done here)

- **New webui UI** for the input-processor / RIAA — there is currently no RIAA UI (only a dormant, unused `/module/riaa` client in `api/pipewire.ts`). Rename that client's base to `/module/input-processor` (and optionally the `RIAA*` TS type names) opportunistically; building an actual "advanced RIAA" settings screen is future work, kept hidden per the product decision.
- **Renaming the git repo** `hifiberry/riaa` itself — only the produced Debian package renames; the repo/clone URL stays `hifiberry/riaa`.
- **Migration of saved RIAA settings** — clean break; the plugin's own `~/.state/ladspa/riaa.ini` persistence is keyed by the LADSPA label (`riaa`, unchanged), so per-plugin saved values survive; only pw-api's `settings.rs` save/restore keys change.

## Self-review notes

- Global constraints (node name, full rename, RIAA-off default, raw-signal recognition, clean break, no-PR delivery) each map to a task: node name → A2/B1/C1/D1; full rename → A3/B1; RIAA-off → A1 (+A2 conf); raw recognition → C1 (no enable); clean break → A3 Provides/Replaces/Conflicts + F4; delivery → each phase's "push main"/"push hbosng".
- Node-name string `input-processor` and monitor/output suffixes are consistent across A2 (conf), B1 (NodeState + link-rules), C1 (`input-processor.monitor`), and F5/F6 verification.
- The param-key prefix decision is explicit: filter-graph node name = `input-processor` (A2) ⇒ pw-cli keys `input-processor:*` (B1), verified in F5. If F5 shows the prefix didn't follow, A2's filter-graph node name is the single lever to fix.
- The `.so`/label `riaa` and LADSPA port labels stay RIAA-named throughout (A1/A2/B1) — only node/package/module/route identities change.

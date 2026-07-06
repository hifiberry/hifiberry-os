# analog-recognition Plugin + Packaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Package `hifiberry/analog-recognition` as a HiFiBerryOS player plugin (registered in the webui, acr, and configserver), add a user-facing "Recognize tracks" setting that gates songrec, and include it in the `hbos-full` image.

**Architecture:** The plugin registers itself from `debian/postinst` (drop-ins in `/etc/hifiberry/players.d`, `/etc/audiocontrol/players.d`, `/etc/configserver/conf.d`), exactly like `hifiberry-squeezelite`. It stays a `--user` systemd service. The Rust binary reads a `songrec_enabled` flag from configurator's ConfigDB each poll interval; when off it publishes `"Unknown artist"` / `"Unknown song"` instead of running songrec, while VU-meter play/stop is unaffected. This plan depends on the **Plugin-Settings Framework** plan (the descriptor `settings` array + `/api/v1/players/<service>/settings` endpoint must exist for the toggle to render and persist).

**Tech Stack:** Rust (tokio, reqwest, wiremock), Debian packaging (debhelper 13, `dh_installsystemduser`, sbuild), Bash.

## Global Constraints

- **Upstream repo:** Tasks 1–4 modify `github.com/hifiberry/analog-recognition`. Work in a fresh clone (`git clone https://github.com/hifiberry/analog-recognition && cd analog-recognition`); commit there and push. Tasks 5–6 modify this repo (`hifiberryos-ng`).
- **Service scope:** `--user` unit at `/usr/lib/systemd/user/analog-recognition.service` (unchanged). Do NOT convert to a system service.
- **ConfigDB key:** `player.analog-recognition.songrec_enabled`, stored as `"true"`/`"false"`. Absent ⇒ default `true` (recognition on). All error paths fail **open** (recognition on).
- **Descriptor maintainer:** `HiFiBerry` (HiFiBerry-owned player), not `"Wanted"`.
- **Runtime deps:** `songrec` (existing), plus `hifiberry-audiocontrol` and `hifiberry-vu-meter`.
- **Version bump:** `debian/changelog` → `0.2.0`.
- **Build style (this repo):** clone-based `build.sh` tracking `main` HEAD; no local debian overlay (upstream ships its own `debian/`).
- Never add `Co-Authored-By` lines to commits.
- Rust tests: `cargo test` in the clone. Package build: `packages/analog-recognition/build.sh` in this repo.

---

### Task 1: Rust — `[configurator]` config section

**Files:**
- Modify: `src/config.rs` (in the analog-recognition clone)

**Interfaces:**
- Produces: `Config.configurator: ConfiguratorConfig` (serde `default`); `ConfiguratorConfig { base_url: String, songrec_enabled_key: String, setting_poll_secs: u64 }` with a `Default` impl and per-field serde defaults.

- [ ] **Step 1: Write the failing test**

Add to the `#[cfg(test)] mod tests` in `src/config.rs`:

```rust
    #[test]
    fn configurator_defaults_when_section_omitted() {
        let toml_str = r#"
            [audiocontrol]
            base_url = "http://localhost:1080/api"
            player_name = "analog"

            [songrec]
            device = "riaa.monitor"
            request_interval_secs = 10
            binary = "songrec"

            [vu_meter]
            ws_url = "ws://localhost:2717/api/v1/levels"
            start_threshold = 40
            stop_threshold = 40
            start_debounce_secs = 1
            stop_debounce_secs = 20
        "#;
        let cfg: Config = toml::from_str(toml_str).unwrap();
        assert_eq!(cfg.configurator.base_url, "http://localhost:1081/api/v1");
        assert_eq!(
            cfg.configurator.songrec_enabled_key,
            "player.analog-recognition.songrec_enabled"
        );
        assert_eq!(cfg.configurator.setting_poll_secs, 10);
    }

    #[test]
    fn parses_configurator_section() {
        let toml_str = r#"
            [audiocontrol]
            base_url = "http://localhost:1080/api"
            player_name = "analog"

            [songrec]
            device = "riaa.monitor"
            request_interval_secs = 10
            binary = "songrec"

            [vu_meter]
            ws_url = "ws://localhost:2717/api/v1/levels"
            start_threshold = 40
            stop_threshold = 40
            start_debounce_secs = 1
            stop_debounce_secs = 20

            [configurator]
            base_url = "http://example:9/api/v1"
            songrec_enabled_key = "player.analog-recognition.songrec_enabled"
            setting_poll_secs = 5
        "#;
        let cfg: Config = toml::from_str(toml_str).unwrap();
        assert_eq!(cfg.configurator.base_url, "http://example:9/api/v1");
        assert_eq!(cfg.configurator.setting_poll_secs, 5);
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cargo test --lib config::tests::configurator_defaults_when_section_omitted`
Expected: FAIL to compile — `Config` has no field `configurator`.

- [ ] **Step 3: Write minimal implementation**

In `src/config.rs`, add the field to `Config`:

```rust
#[derive(Debug, Clone, Deserialize)]
pub struct Config {
    pub audiocontrol: AudioControlConfig,
    pub songrec: SongrecConfig,
    pub vu_meter: VuMeterConfig,
    #[serde(default)]
    pub logging: LoggingConfig,
    #[serde(default)]
    pub configurator: ConfiguratorConfig,
}
```

Add the new struct + defaults (place near `LoggingConfig`):

```rust
#[derive(Debug, Clone, Deserialize)]
pub struct ConfiguratorConfig {
    #[serde(default = "default_configurator_base_url")]
    pub base_url: String,
    #[serde(default = "default_songrec_enabled_key")]
    pub songrec_enabled_key: String,
    #[serde(default = "default_setting_poll_secs")]
    pub setting_poll_secs: u64,
}

fn default_configurator_base_url() -> String {
    "http://localhost:1081/api/v1".to_string()
}
fn default_songrec_enabled_key() -> String {
    "player.analog-recognition.songrec_enabled".to_string()
}
fn default_setting_poll_secs() -> u64 {
    10
}

impl Default for ConfiguratorConfig {
    fn default() -> Self {
        ConfiguratorConfig {
            base_url: default_configurator_base_url(),
            songrec_enabled_key: default_songrec_enabled_key(),
            setting_poll_secs: default_setting_poll_secs(),
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cargo test --lib config::`
Expected: PASS (existing `parses_full_config`, `logging_defaults_when_omitted`, plus the two new tests).

- [ ] **Step 5: Commit**

```bash
git add src/config.rs
git commit -m "feat(config): add [configurator] section for plugin-settings access"
```

---

### Task 2: Rust — `SettingsClient` (reads songrec_enabled from configurator)

**Files:**
- Create: `src/settings.rs`
- Modify: `src/main.rs` (add `mod settings;`)
- Test: `tests/settings.rs`

**Interfaces:**
- Produces: `settings::SettingsClient::new(base_url: String, songrec_enabled_key: String) -> SettingsClient`; `async fn songrec_enabled(&self) -> bool` (fail-open: any error / 404 / unparseable ⇒ `true`).

- [ ] **Step 1: Write the failing test**

Create `tests/settings.rs`:

```rust
use analog_recognition::settings::SettingsClient;
use wiremock::matchers::{method, path};
use wiremock::{Mock, MockServer, ResponseTemplate};

const KEY: &str = "player.analog-recognition.songrec_enabled";

fn client(base: String) -> SettingsClient {
    SettingsClient::new(base, KEY.to_string())
}

#[tokio::test]
async fn false_when_stored_false() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path(format!("/key/{KEY}")))
        .respond_with(ResponseTemplate::new(200).set_body_json(serde_json::json!({
            "status": "success", "data": { "key": KEY, "value": "false" }
        })))
        .mount(&server)
        .await;
    assert_eq!(client(server.uri()).songrec_enabled().await, false);
}

#[tokio::test]
async fn true_when_stored_true() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path(format!("/key/{KEY}")))
        .respond_with(ResponseTemplate::new(200).set_body_json(serde_json::json!({
            "status": "success", "data": { "key": KEY, "value": "true" }
        })))
        .mount(&server)
        .await;
    assert_eq!(client(server.uri()).songrec_enabled().await, true);
}

#[tokio::test]
async fn default_true_when_key_absent_404() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path(format!("/key/{KEY}")))
        .respond_with(ResponseTemplate::new(404))
        .mount(&server)
        .await;
    assert_eq!(client(server.uri()).songrec_enabled().await, true);
}

#[tokio::test]
async fn default_true_on_connection_failure() {
    // Port 1 is reserved; nothing listens.
    assert_eq!(client("http://127.0.0.1:1".to_string()).songrec_enabled().await, true);
}
```

This test uses the crate as a library (`use analog_recognition::...`). If `Cargo.toml` has no `[lib]`, the crate is binary-only and integration tests cannot import modules. Confirm/behave accordingly in Step 3.

- [ ] **Step 2: Run test to verify it fails**

Run: `cargo test --test settings`
Expected: FAIL — `unresolved import analog_recognition::settings` (module + possibly lib target missing).

- [ ] **Step 3: Write minimal implementation**

Create `src/settings.rs`:

```rust
use serde::Deserialize;

/// Reads plugin settings from the configurator ConfigDB over HTTP.
pub struct SettingsClient {
    http: reqwest::Client,
    base_url: String,
    songrec_enabled_key: String,
}

#[derive(Deserialize)]
struct KeyResponse {
    data: Option<KeyData>,
}

#[derive(Deserialize)]
struct KeyData {
    value: Option<String>,
}

impl SettingsClient {
    pub fn new(base_url: String, songrec_enabled_key: String) -> Self {
        SettingsClient {
            http: reqwest::Client::new(),
            base_url,
            songrec_enabled_key,
        }
    }

    fn key_url(&self) -> String {
        format!(
            "{}/key/{}",
            self.base_url.trim_end_matches('/'),
            self.songrec_enabled_key
        )
    }

    /// Whether songrec recognition is enabled. Fail-open: any error, a missing
    /// key (404), or an unparseable response yields `true` (recognition on).
    pub async fn songrec_enabled(&self) -> bool {
        self.fetch_flag().await.unwrap_or(true)
    }

    async fn fetch_flag(&self) -> Option<bool> {
        let resp = self.http.get(self.key_url()).send().await.ok()?;
        if !resp.status().is_success() {
            return None; // 404 (unset) -> default true
        }
        let body: KeyResponse = resp.json().await.ok()?;
        let value = body.data?.value?;
        Some(matches!(
            value.trim().to_ascii_lowercase().as_str(),
            "true" | "1" | "yes" | "on"
        ))
    }
}
```

Enable module use from both the binary and integration tests. If `Cargo.toml` has no `[lib]` target, add one so `tests/settings.rs` can `use analog_recognition::settings::...`. Add to `Cargo.toml`:

```toml
[lib]
name = "analog_recognition"
path = "src/lib.rs"
```

Create `src/lib.rs` exposing the modules the tests and binary share:

```rust
pub mod audiocontrol;
pub mod config;
pub mod settings;
pub mod songrec;
pub mod vu_meter;
```

Update `src/main.rs`: replace its `mod audiocontrol; mod config; mod songrec; mod vu_meter;` declarations with a single import from the library crate, and reference items via the crate path:

```rust
use analog_recognition::{audiocontrol, config, settings, songrec, vu_meter};
```

(Leave the rest of `main.rs` untouched for now; Task 3 wires `settings` in.)

- [ ] **Step 4: Run tests to verify they pass**

Run: `cargo test --test settings`
Expected: PASS (4 passed). Also run `cargo build` to confirm the binary still compiles against the new lib layout.

- [ ] **Step 5: Commit**

```bash
git add src/settings.rs src/lib.rs src/main.rs Cargo.toml
git commit -m "feat(settings): read songrec_enabled from configurator (fail-open)"
```

---

### Task 3: Rust — gate recognition on the setting

**Files:**
- Modify: `src/songrec.rs` (add `unknown_track`, gate `run_recognition_task`)
- Modify: `src/main.rs` (construct `SettingsClient`, pass poll interval)
- Test: add a unit test for `unknown_track` in `src/songrec.rs`

**Interfaces:**
- Consumes: `SettingsClient::songrec_enabled` (Task 2); existing `AudioControlClient::send_song_changed`, `run_songrec_once` (unchanged signature).
- Produces: `songrec::unknown_track() -> RecognizedTrack`; new signature `run_recognition_task(cfg: &SongrecConfig, settings: &SettingsClient, client: &AudioControlClient, song_reset: &Arc<Notify>, poll: Duration) -> !`.

Note: the gating lives entirely in `run_recognition_task`; `run_songrec_once` is unchanged, so its existing tests keep passing. When disabled mid-playback, the `tokio::select!` drops the `run_songrec_once` future, and songrec is killed via its existing `kill_on_drop(true)`.

- [ ] **Step 1: Write the failing test**

Add to the `#[cfg(test)] mod tests` in `src/songrec.rs`:

```rust
    #[test]
    fn unknown_track_has_placeholder_fields() {
        let t = unknown_track();
        assert_eq!(t.artist, "Unknown artist");
        assert_eq!(t.title, "Unknown song");
        assert_eq!(t.album, None);
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cargo test --lib songrec::tests::unknown_track_has_placeholder_fields`
Expected: FAIL to compile — `unknown_track` not found.

- [ ] **Step 3: Write minimal implementation**

In `src/songrec.rs`, add the import and helper near the top (after the `RecognizedTrack` definition):

```rust
use crate::settings::SettingsClient;
use std::time::Duration;

/// The placeholder track published when songrec recognition is disabled.
pub fn unknown_track() -> RecognizedTrack {
    RecognizedTrack {
        title: "Unknown song".to_string(),
        artist: "Unknown artist".to_string(),
        album: None,
        genre: None,
    }
}
```

Replace `run_recognition_task` with the gated version:

```rust
pub async fn run_recognition_task(
    cfg: &SongrecConfig,
    settings: &SettingsClient,
    client: &AudioControlClient,
    song_reset: &Arc<Notify>,
    poll: Duration,
) -> ! {
    let mut backoff = Duration::from_secs(1);
    loop {
        if !settings.songrec_enabled().await {
            // Disabled: publish the placeholder track and poll until re-enabled.
            if let Err(e) = client.send_song_changed(&unknown_track()).await {
                log::warn!("failed to publish unknown track: {e}");
            }
            tokio::time::sleep(poll).await;
            continue;
        }
        tokio::select! {
            result = run_songrec_once(cfg, client, song_reset) => {
                match result {
                    Ok(()) => log::warn!("songrec exited, restarting"),
                    Err(e) => log::warn!("songrec failed: {e}, restarting"),
                }
                tokio::time::sleep(backoff).await;
                backoff = (backoff * 2).min(Duration::from_secs(30));
            }
            _ = wait_until_disabled(settings, poll) => {
                // The run_songrec_once future is dropped here; its child is
                // killed via kill_on_drop. Loop re-checks and enters the
                // disabled branch above.
                log::info!("songrec disabled via setting, stopping recognition");
                backoff = Duration::from_secs(1);
            }
        }
    }
}

/// Resolves once the songrec_enabled setting reads false.
async fn wait_until_disabled(settings: &SettingsClient, poll: Duration) {
    let mut interval = tokio::time::interval(poll);
    interval.tick().await; // consume the immediate first tick
    loop {
        interval.tick().await;
        if !settings.songrec_enabled().await {
            return;
        }
    }
}
```

In `src/main.rs`, construct the settings client and pass it plus the poll interval. Replace the recognition-task spawn block:

```rust
    let settings = Arc::new(settings::SettingsClient::new(
        cfg.configurator.base_url.clone(),
        cfg.configurator.songrec_enabled_key.clone(),
    ));
    let poll = std::time::Duration::from_secs(cfg.configurator.setting_poll_secs);

    let rec_client = client.clone();
    let rec_settings = settings.clone();
    let songrec_cfg = cfg.songrec.clone();
    let rec_handle = tokio::spawn(async move {
        songrec::run_recognition_task(&songrec_cfg, &rec_settings, &rec_client, &song_reset, poll).await
    });
```

- [ ] **Step 4: Run tests + build to verify**

Run: `cargo test && cargo build`
Expected: all tests pass (existing audiocontrol/songrec/vu_meter/config tests + new `unknown_track` + Task 2 settings tests); binary compiles.

- [ ] **Step 5: Commit**

```bash
git add src/songrec.rs src/main.rs
git commit -m "feat(songrec): gate recognition on songrec_enabled; publish Unknown when off"
```

---

### Task 4: Packaging — drop-ins, icon, deps, config, README

**Files (in the analog-recognition clone):**
- Create: `debian/postinst`
- Create: `debian/postrm`
- Create: `package-files/usr/share/hifiberry-analog-recognition/icons/analog.svg`
- Modify: `debian/rules` (install icon)
- Modify: `debian/control` (add deps)
- Modify: `debian/changelog` (0.2.0)
- Modify: `package-files/etc/analog-recognition/config.toml` (add `[configurator]`)
- Modify: `README.md`

**Interfaces:**
- Produces: on install, `/etc/hifiberry/players.d/analog.json` (+ `icons/analog.svg`), `/etc/configserver/conf.d/analog-recognition.json`, `/etc/audiocontrol/players.d/analog.json`; on remove, all four are deleted.

- [ ] **Step 1: Write `debian/postinst`**

Create `debian/postinst` (mirrors `hifiberry-squeezelite.postinst`; the webui descriptor carries the `settings` array):

```bash
#!/bin/bash
set -e

case "$1" in
    configure)
        # Register in Web UI player registry
        HBOS_PLAYERS_D="/etc/hifiberry/players.d"
        mkdir -p "$HBOS_PLAYERS_D/icons"

        cat > "$HBOS_PLAYERS_D/analog.json" <<'PLAYEREOF'
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
PLAYEREOF

        if [ -f /usr/share/hifiberry-analog-recognition/icons/analog.svg ]; then
            cp /usr/share/hifiberry-analog-recognition/icons/analog.svg "$HBOS_PLAYERS_D/icons/analog.svg"
        fi

        echo "Registered Analog Input in Web UI player registry."

        # Register systemd permissions via configserver drop-in
        mkdir -p /etc/configserver/conf.d
        cat > /etc/configserver/conf.d/analog-recognition.json <<'CONFEOF'
{
    "systemd": {
        "analog-recognition": "all"
    }
}
CONFEOF

        echo "Configserver drop-in installed for analog-recognition."

        # Register with ACR
        if [ -d /etc/audiocontrol ]; then
            ACR_PLAYERS_D="/etc/audiocontrol/players.d"
            mkdir -p "$ACR_PLAYERS_D"
            cat > "$ACR_PLAYERS_D/analog.json" <<'ACREOF'
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
ACREOF
            echo "Registered analog with ACR."
        fi
        ;;

    abort-upgrade|abort-remove|abort-deconfigure)
        ;;

    *)
        echo "postinst called with unknown argument \`$1'" >&2
        exit 1
        ;;
esac

#DEBHELPER#

exit 0
```

Note: the `#DEBHELPER#` token lets `dh_installsystemduser` inject the user-service enable block (auto-enable on install, matching squeezelite). Make it executable: `chmod 755 debian/postinst`.

- [ ] **Step 2: Write `debian/postrm`**

Create `debian/postrm`:

```bash
#!/bin/bash
set -e

if [ "$1" = "remove" ] || [ "$1" = "purge" ]; then
    rm -f /etc/hifiberry/players.d/analog.json
    rm -f /etc/hifiberry/players.d/icons/analog.svg
    rm -f /etc/configserver/conf.d/analog-recognition.json
    rm -f /etc/audiocontrol/players.d/analog.json
fi

#DEBHELPER#

exit 0
```

`chmod 755 debian/postrm`.

- [ ] **Step 3: Create the icon**

Create `package-files/usr/share/hifiberry-analog-recognition/icons/analog.svg` (single-colour, `currentColor`, themes like other player icons — a vinyl record):

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="9"/>
  <circle cx="12" cy="12" r="4"/>
  <circle cx="12" cy="12" r="1"/>
</svg>
```

- [ ] **Step 4: Install the icon in `debian/rules`**

In `debian/rules`, add to `override_dh_auto_install` (after the existing `cp` of config.toml):

```make
	mkdir -p debian/hifiberry-analog-recognition/usr/share/hifiberry-analog-recognition/icons
	cp package-files/usr/share/hifiberry-analog-recognition/icons/analog.svg \
		debian/hifiberry-analog-recognition/usr/share/hifiberry-analog-recognition/icons/
```

- [ ] **Step 5: Add runtime deps in `debian/control`**

In the `Package: hifiberry-analog-recognition` stanza, extend `Depends:`:

```
Depends: ${shlibs:Depends}, ${misc:Depends},
         songrec,
         hifiberry-audiocontrol,
         hifiberry-vu-meter
```

- [ ] **Step 6: Add `[configurator]` to the shipped config**

Append to `package-files/etc/analog-recognition/config.toml`:

```toml

[configurator]
base_url = "http://localhost:1081/api/v1"
songrec_enabled_key = "player.analog-recognition.songrec_enabled"
setting_poll_secs = 10
```

- [ ] **Step 7: Bump the changelog**

Prepend to `debian/changelog`:

```
hifiberry-analog-recognition (0.2.0) stable; urgency=medium

  * Register as a HiFiBerryOS player plugin (webui players.d + configserver
    permission + ACR players.d drop-in) via postinst/postrm.
  * Add "Recognize tracks" setting: when off, publish "Unknown artist" /
    "Unknown song" instead of running songrec.
  * Depend on hifiberry-audiocontrol and hifiberry-vu-meter.

 -- HiFiBerry <support@hifiberry.com>  Mon, 06 Jul 2026 12:00:00 +0000

```

- [ ] **Step 8: Update the README**

In `README.md`, replace the "Required AudioControl configuration" section (the manual `audiocontrol.json` edit) with a note that registration is automatic via the package (players.d drop-in) and document the "Recognize tracks" setting and its ConfigDB key `player.analog-recognition.songrec_enabled`.

- [ ] **Step 9: Commit and push upstream**

```bash
git add debian/postinst debian/postrm debian/rules debian/control debian/changelog \
        package-files/usr/share/hifiberry-analog-recognition/icons/analog.svg \
        package-files/etc/analog-recognition/config.toml README.md
git commit -m "feat(packaging): register as HiFiBerryOS plugin with songrec toggle (0.2.0)"
git push origin main
```

---

### Task 5: This repo — `packages/analog-recognition/` build files

**Files (in `hifiberryos-ng`):**
- Create: `packages/analog-recognition/build.sh`
- Create: `packages/analog-recognition/clean.sh`
- Create: `packages/analog-recognition/README.md`

**Interfaces:**
- Produces: a `build-all`-discoverable package that clones the upstream repo, builds with sbuild, and leaves `hifiberry-analog-recognition_*.deb` in the package dir.

- [ ] **Step 1: Write `build.sh`**

Create `packages/analog-recognition/build.sh` (clone-based, sbuild; models riaa's clone logic + songrec's artifact cleanup; upstream ships its own `debian/`, so no overlay):

```bash
#!/bin/bash
set -e

# Enable cross-compile support if configured
_CC_ENV="$(dirname "$0")/../../scripts/cross-compile-env.sh"
if [ -f "$_CC_ENV" ]; then source "$_CC_ENV"; else echo "Not using cross-compilation (${_CC_ENV} does not exist)"; fi

PACKAGE="analog-recognition"
REPO_URL="https://github.com/hifiberry/analog-recognition"

if [[ "$1" == "--clean" ]]; then
    rm -rf "$PACKAGE"
    rm -f hifiberry-analog-recognition_* hifiberry-analog-recognition-*
    echo "Cleanup completed."
    exit 0
fi

# Clone or update upstream (tracks main HEAD)
if [[ -d "$PACKAGE/.git" ]]; then
    echo "Updating $PACKAGE from $REPO_URL..."
    ( cd "$PACKAGE" && git pull )
else
    echo "Cloning $PACKAGE from $REPO_URL..."
    git clone "$REPO_URL" "$PACKAGE"
fi

cd "$PACKAGE"

if [ -n "$DIST" ]; then
    DIST_ARG="--dist=$DIST"
else
    DIST_ARG=""
fi

echo "Building with sbuild..."
sbuild --chroot-mode=unshare --enable-network --no-clean-source $DIST_ARG

cd ..

# Keep only the .deb; prune other build artifacts
find . -maxdepth 1 \( -name "*.build" -o -name "*.buildinfo" -o -name "*.changes" \
    -o -name "*.dsc" -o -name "*.tar.gz" -o -name "*.tar.xz" \) -delete

LATEST_DEB=$(ls -t hifiberry-analog-recognition_*.deb 2>/dev/null | head -1)
if [ -n "$LATEST_DEB" ]; then
    ls -t hifiberry-analog-recognition_*.deb | tail -n +2 | xargs -r rm -f
fi

echo "Package created:"
ls -lh hifiberry-analog-recognition_*.deb 2>/dev/null || ls -lh *.deb
echo "Build completed successfully!"
```

`chmod 755 packages/analog-recognition/build.sh`.

- [ ] **Step 2: Write `clean.sh`**

Create `packages/analog-recognition/clean.sh`:

```bash
#!/bin/bash
echo "Cleaning up analog-recognition build artifacts..."
rm -rf analog-recognition
rm -f hifiberry-analog-recognition_*
echo "Cleaned up analog-recognition build artifacts."
```

`chmod 755 packages/analog-recognition/clean.sh`.

- [ ] **Step 3: Write `README.md`**

Create `packages/analog-recognition/README.md`:

```markdown
# analog-recognition

Builds `hifiberry-analog-recognition` from
[github.com/hifiberry/analog-recognition](https://github.com/hifiberry/analog-recognition).

Analog-input song recognition (songrec) plus VU-meter-based play/stop state,
published into AudioControl as a generic player named `analog`.

The package registers itself as a HiFiBerryOS player plugin from its
`postinst` (webui `players.d`, configserver permission, ACR `players.d`), so it
appears under "3rd Party Players" in the web UI with an enable/disable toggle
and a "Recognize tracks" (songrec) setting. Runs as a `--user` systemd service.

`build.sh` clones the upstream repo (tracking `main`) and builds with sbuild;
the upstream repo ships its own `debian/`, so there is no local overlay here.
```

- [ ] **Step 4: Build to verify**

Run: `cd packages/analog-recognition && ./build.sh`
Expected: clones upstream, sbuild completes, `hifiberry-analog-recognition_0.2.0_arm64.deb` present. (Requires the sbuild toolchain per repo `build.md`.)

- [ ] **Step 5: Verify the deb contents**

Run: `dpkg-deb -c packages/analog-recognition/hifiberry-analog-recognition_*.deb | grep -E 'analog.svg|analog-recognition.service|config.toml'`
Expected: shows the binary, the user unit, `config.toml`, and `usr/share/hifiberry-analog-recognition/icons/analog.svg`. (The players.d/conf.d drop-ins are created by postinst at install time, not in the deb.)

- [ ] **Step 6: Commit**

```bash
git add packages/analog-recognition/build.sh packages/analog-recognition/clean.sh packages/analog-recognition/README.md
git commit -m "build: add analog-recognition package (clone-based, tracks main)"
```

---

### Task 6: This repo — include in `hbos-full`

**Files:**
- Modify: `packages/hifiberryos/src/debian/control`
- Modify: `packages/hifiberryos/src/debian/changelog`

**Interfaces:** none (meta-package dependency addition).

- [ ] **Step 1: Add the dependency**

In `packages/hifiberryos/src/debian/control`, in the `Package: hbos-full` `Depends:` list, add after `hifiberry-vu-meter,` (line ~78):

```
         hifiberry-analog-recognition,
```

- [ ] **Step 2: Document it in the Description**

In the same `hbos-full` stanza's Description bullet list, add after the RAAT bullet:

```
  - Analog-input track recognition plugin (hifiberry-analog-recognition)
```

- [ ] **Step 3: Bump the meta changelog**

Prepend a new entry to `packages/hifiberryos/src/debian/changelog` (use the next version after the current top entry; keep the existing footer format):

```
hifiberryos-meta (X.Y) stable; urgency=medium

  * Add hifiberry-analog-recognition to hbos-full dependencies

 -- HiFiBerry <support@hifiberry.com>  Mon, 06 Jul 2026 12:00:00 +0000

```

Replace `X.Y` with the incremented version (read the current top line of `debian/changelog` first, e.g. `0.8` → `0.9`).

- [ ] **Step 4: Verify the control parses**

Run: `dpkg-parsechangelog -l packages/hifiberryos/src/debian/changelog >/dev/null && echo OK`
Expected: `OK` (changelog is well-formed).

- [ ] **Step 5: Commit**

```bash
git add packages/hifiberryos/src/debian/control packages/hifiberryos/src/debian/changelog
git commit -m "build(hbos-full): include hifiberry-analog-recognition plugin"
```

---

## End-to-end verification (on device `matuschd@192.168.11.136`)

Requires the framework plan's configurator + webui debs installed first.

1. Install the rebuilt `hifiberry-analog-recognition_0.2.0` deb.
2. Drop-ins exist: `/etc/hifiberry/players.d/analog.json` (+ `icons/analog.svg`), `/etc/configserver/conf.d/analog-recognition.json`, `/etc/audiocontrol/players.d/analog.json`.
3. `curl -s localhost:1081/api/v1/players | jq '.data.players[] | select(.provided_by=="analog-recognition")'` → shows the entry with `allow_change:true` and `settings[0].value == true`.
4. Webui Players view: "Analog Input" appears under 3rd Party Players with a working service toggle and, on expand, a "Recognize tracks" toggle.
5. Turn "Recognize tracks" **off** + Save → `curl -s localhost:1081/api/v1/key/player.analog-recognition.songrec_enabled` returns `"false"`; within ~10s, with a signal present, `/api/now-playing` (acr) shows `Unknown artist` / `Unknown song`; play/stop still tracks the VU meter.
6. Turn it back **on** → recognition resumes within ~10s, no service restart.
7. `apt purge hifiberry-analog-recognition` removes all four drop-ins.

## Self-review notes

- Spec A1 (descriptor incl. settings) → Task 4 Step 1. A2 (postrm) → Task 4 Step 2. A3 (icon) → Task 4 Steps 3–4. A4 (user service auto-enable) → `#DEBHELPER#` in Task 4 Step 1. A5 (control deps) → Task 4 Step 5. A6 (README) → Task 4 Step 8. A7 (songrec behavior + ConfigDB read) → Tasks 1–3. B1 (build files) → Task 5. B2 (hbos-full) → Task 6. Covered.
- `run_songrec_once` signature is deliberately unchanged (Task 3 note) → existing upstream tests keep passing.
- Cross-plan dependency stated up front: the descriptor `settings` array and `PUT /players/<service>/settings` come from the Plugin-Settings Framework plan; the ConfigDB key name `player.analog-recognition.songrec_enabled` matches on both sides (framework Task 1 `setting_value_key`; this plan's config default + descriptor key `songrec_enabled` under service `analog-recognition`).
- Fail-open default `true` is consistent across `SettingsClient` (Task 2), config default, and the descriptor default.

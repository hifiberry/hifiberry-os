# Plugin-Settings Framework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a HiFiBerryOS player plugin declare configurable settings in its drop-in descriptor and have them render + persist through the web UI, generically (no per-plugin special-casing).

**Architecture:** A plugin's `/etc/hifiberry/players.d/<name>.json` descriptor gains an optional `settings` array (typed controls). configurator's `PlayerRegistryHandler` passes the schema through `GET /api/v1/players` enriched with each setting's current value (read from ConfigDB), and a new `PUT /api/v1/players/<service>/settings` persists values namespaced as `player.<service>.<key>`. The webui's `PlayerCard` renders a generic settings section for any external plugin. This is subsystem C of the analog-recognition design; the songrec toggle (separate plan) is its first consumer.

**Tech Stack:** Python 3 / Flask (configurator), Vue 3 + TypeScript + Vitest (hbos-ui), SQLite key/value store (ConfigDB).

## Global Constraints

- **Two vendored upstream repos change.** configurator lives at `packages/configurator/configurator/` (Python package root; the `configurator/` package dir is inside it). hbos-ui lives at `packages/webui/hbos-ui/`. Both are git checkouts — commit inside each as its own history.
- **ConfigDB key convention:** `player.<systemd_service>.<key>`. Values are stored as TEXT; booleans serialize as the strings `"true"` / `"false"`.
- **Setting schema fields:** `key` (str, required), `type` (`"toggle"` | `"select"`, required), `label` (str, required), `default` (required — bool for toggle, str for select), `description` (str, optional), `options` (list of `{value,label}`, required for `select` only).
- **Backward compatibility:** a descriptor with no `settings` key yields an empty settings list; nothing about existing players (mpd/raat/librespot/…) changes.
- **configurator has no existing tests.** This plan introduces pytest under `packages/configurator/configurator/tests/`. Run configurator tests from `packages/configurator/configurator/` with `python3 -m pytest tests/ -v`.
- **hbos-ui tests:** Vitest, colocated in `__tests__/`. Run from `packages/webui/hbos-ui/` with `npx vitest run <path>`.
- Never add `Co-Authored-By` lines to commits (project rule).

---

### Task 1: configurator — pure settings helpers

Pure, Flask-free functions for key naming, value coercion, and schema sanitisation. These are the testable core the Flask handlers call.

**Files:**
- Modify: `packages/configurator/configurator/configurator/handlers/player_registry_handler.py`
- Create: `packages/configurator/configurator/tests/__init__.py` (empty)
- Test: `packages/configurator/configurator/tests/test_player_settings_helpers.py`

**Interfaces:**
- Produces (module-level functions in `player_registry_handler.py`):
  - `SETTING_TYPES = ("toggle", "select")`
  - `setting_value_key(systemd_service: str, key: str) -> str`
  - `coerce_setting_value(setting_type: str, raw) -> bool | str | None`
  - `serialize_setting_value(setting_type: str, value) -> str`
  - `sanitize_settings(descriptor: dict) -> list[dict]`

- [ ] **Step 1: Write the failing test**

Create `packages/configurator/configurator/tests/__init__.py` (empty file), then `packages/configurator/configurator/tests/test_player_settings_helpers.py`:

```python
from configurator.handlers.player_registry_handler import (
    setting_value_key,
    coerce_setting_value,
    serialize_setting_value,
    sanitize_settings,
)


def test_setting_value_key_namespaces_by_service():
    assert setting_value_key("analog-recognition", "songrec_enabled") == \
        "player.analog-recognition.songrec_enabled"


def test_coerce_toggle_from_stored_strings():
    assert coerce_setting_value("toggle", "true") is True
    assert coerce_setting_value("toggle", "false") is False
    assert coerce_setting_value("toggle", "1") is True
    assert coerce_setting_value("toggle", True) is True
    assert coerce_setting_value("toggle", None) is None


def test_coerce_select_returns_string_or_none():
    assert coerce_setting_value("select", "medium") == "medium"
    assert coerce_setting_value("select", None) is None


def test_serialize_toggle_uses_true_false_strings():
    assert serialize_setting_value("toggle", True) == "true"
    assert serialize_setting_value("toggle", False) == "false"
    assert serialize_setting_value("select", "high") == "high"


def test_sanitize_settings_drops_invalid_and_keeps_valid():
    descriptor = {
        "settings": [
            {"key": "songrec_enabled", "type": "toggle", "label": "Recognize", "default": True},
            {"key": "bad_no_type", "label": "x", "default": 1},
            {"key": "mode", "type": "select", "label": "Mode", "default": "a",
             "options": [{"value": "a", "label": "A"}]},
            {"key": "bad_type", "type": "slider", "label": "y", "default": 1},
        ]
    }
    out = sanitize_settings(descriptor)
    keys = [s["key"] for s in out]
    assert keys == ["songrec_enabled", "mode"]
    assert out[0]["type"] == "toggle"


def test_sanitize_settings_absent_is_empty():
    assert sanitize_settings({"name": "x"}) == []
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/configurator/configurator && python3 -m pytest tests/test_player_settings_helpers.py -v`
Expected: FAIL with `ImportError: cannot import name 'setting_value_key'`.

- [ ] **Step 3: Write minimal implementation**

In `packages/configurator/configurator/configurator/handlers/player_registry_handler.py`, add after the existing `REQUIRED_FIELDS = (...)` line:

```python
SETTING_TYPES = ("toggle", "select")
_SETTING_REQUIRED = ("key", "type", "label", "default")


def setting_value_key(systemd_service, key):
    """ConfigDB key for a plugin setting value."""
    return f"player.{systemd_service}.{key}"


def coerce_setting_value(setting_type, raw):
    """Coerce a stored TEXT value (or native value / None) to its typed form."""
    if raw is None:
        return None
    if setting_type == "toggle":
        if isinstance(raw, bool):
            return raw
        return str(raw).strip().lower() in ("true", "1", "yes", "on")
    return str(raw)


def serialize_setting_value(setting_type, value):
    """Serialize a typed value to the TEXT form stored in ConfigDB."""
    if setting_type == "toggle":
        return "true" if value else "false"
    return str(value)


def sanitize_settings(descriptor):
    """Return the descriptor's declared settings, dropping malformed entries."""
    raw = descriptor.get("settings")
    if not isinstance(raw, list):
        return []
    clean = []
    for entry in raw:
        if not isinstance(entry, dict):
            continue
        if any(f not in entry for f in _SETTING_REQUIRED):
            continue
        if entry["type"] not in SETTING_TYPES:
            continue
        clean.append(entry)
    return clean
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/configurator/configurator && python3 -m pytest tests/test_player_settings_helpers.py -v`
Expected: PASS (6 passed).

- [ ] **Step 5: Commit** (inside the configurator repo)

```bash
cd packages/configurator/configurator
git add configurator/handlers/player_registry_handler.py tests/__init__.py tests/test_player_settings_helpers.py
git commit -m "feat(players): pure helpers for plugin settings schema and values"
```

---

### Task 2: configurator — enrich `/api/v1/players` with settings + values

Make the handler ConfigDB-aware and include each descriptor's settings (with current values) in the players listing.

**Files:**
- Modify: `packages/configurator/configurator/configurator/handlers/player_registry_handler.py`
- Modify: `packages/configurator/configurator/configurator/server.py:75` (pass configdb into the handler)
- Test: `packages/configurator/configurator/tests/test_player_registry_listing.py`

**Interfaces:**
- Consumes: `sanitize_settings`, `coerce_setting_value`, `setting_value_key` (Task 1); `ConfigDB.get(key, default=None)` / `ConfigDB.set(key, value)`.
- Produces:
  - `PlayerRegistryHandler.__init__(self, configdb=None, players_d_dir=PLAYERS_D_DIR)`
  - `PlayerRegistryHandler._load_descriptors(self) -> list[dict]`
  - `PlayerRegistryHandler._build_players(self) -> list[dict]` (each player dict now carries a `"settings"` list; each setting has an added `"value"` key)

- [ ] **Step 1: Write the failing test**

Create `packages/configurator/configurator/tests/test_player_registry_listing.py`:

```python
import json
import os
from configurator.handlers.player_registry_handler import PlayerRegistryHandler
from configurator.configdb import ConfigDB


def _write_descriptor(dir_path, filename, descriptor):
    os.makedirs(dir_path, exist_ok=True)
    with open(os.path.join(dir_path, filename), "w") as f:
        json.dump(descriptor, f)


def test_build_players_includes_settings_with_default_value(tmp_path):
    players_d = tmp_path / "players.d"
    _write_descriptor(str(players_d), "analog.json", {
        "name": "Analog Input",
        "provided_by": "analog-recognition",
        "systemd_service": "analog-recognition",
        "icon": "analog",
        "settings": [
            {"key": "songrec_enabled", "type": "toggle",
             "label": "Recognize tracks", "default": True},
        ],
    })
    configdb = ConfigDB(db_path=str(tmp_path / "config.sqlite"))
    handler = PlayerRegistryHandler(configdb=configdb, players_d_dir=str(players_d))

    players = handler._build_players()
    assert len(players) == 1
    settings = players[0]["settings"]
    assert settings[0]["key"] == "songrec_enabled"
    assert settings[0]["value"] is True  # falls back to default when unset


def test_build_players_reads_stored_value(tmp_path):
    players_d = tmp_path / "players.d"
    _write_descriptor(str(players_d), "analog.json", {
        "name": "Analog Input",
        "provided_by": "analog-recognition",
        "systemd_service": "analog-recognition",
        "icon": "analog",
        "settings": [
            {"key": "songrec_enabled", "type": "toggle",
             "label": "Recognize tracks", "default": True},
        ],
    })
    configdb = ConfigDB(db_path=str(tmp_path / "config.sqlite"))
    configdb.set("player.analog-recognition.songrec_enabled", "false")
    handler = PlayerRegistryHandler(configdb=configdb, players_d_dir=str(players_d))

    players = handler._build_players()
    assert players[0]["settings"][0]["value"] is False


def test_build_players_no_settings_key_yields_empty_list(tmp_path):
    players_d = tmp_path / "players.d"
    _write_descriptor(str(players_d), "lms.json", {
        "name": "LMS", "provided_by": "squeezelite",
        "systemd_service": "squeezelite", "icon": "squeezelite",
    })
    configdb = ConfigDB(db_path=str(tmp_path / "config.sqlite"))
    handler = PlayerRegistryHandler(configdb=configdb, players_d_dir=str(players_d))
    assert handler._build_players()[0]["settings"] == []
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/configurator/configurator && python3 -m pytest tests/test_player_registry_listing.py -v`
Expected: FAIL — `TypeError: __init__() got an unexpected keyword argument 'configdb'` (or `_build_players` missing).

- [ ] **Step 3: Write minimal implementation**

In `player_registry_handler.py`, replace the class body's `handle_list_players` region. Add an `__init__`, factor descriptor loading into `_load_descriptors`, and add `_build_players`; keep `handle_list_players`/`handle_player_icon` as thin wrappers. Concretely:

```python
class PlayerRegistryHandler:
    """Handler for external player discovery and icon serving"""

    def __init__(self, configdb=None, players_d_dir=PLAYERS_D_DIR):
        self.configdb = configdb
        self.players_d_dir = players_d_dir
        self.icons_dir = os.path.join(players_d_dir, "icons")

    def _load_descriptors(self):
        """Load valid descriptor dicts from the players.d directory."""
        descriptors = []
        if not os.path.isdir(self.players_d_dir):
            return descriptors
        for filename in sorted(os.listdir(self.players_d_dir)):
            if not filename.endswith(".json"):
                continue
            path = os.path.join(self.players_d_dir, filename)
            try:
                with open(path, "r") as f:
                    descriptor = json.load(f)
            except (json.JSONDecodeError, OSError) as e:
                logger.warning(f"Skipping invalid player descriptor {path}: {e}")
                continue
            if not isinstance(descriptor, dict):
                logger.warning(f"Skipping {path}: not a JSON object")
                continue
            missing = [f for f in REQUIRED_FIELDS if f not in descriptor]
            if missing:
                logger.warning(f"Skipping {path}: missing fields {missing}")
                continue
            descriptors.append(descriptor)
        return descriptors

    def _settings_with_values(self, descriptor):
        """Descriptor settings enriched with the current stored value."""
        service = descriptor["systemd_service"]
        out = []
        for setting in sanitize_settings(descriptor):
            value = None
            if self.configdb is not None:
                raw = self.configdb.get(setting_value_key(service, setting["key"]), default=None)
                value = coerce_setting_value(setting["type"], raw)
            if value is None:
                value = setting["default"]
            out.append({**setting, "value": value})
        return out

    def _build_players(self):
        players = []
        for descriptor in self._load_descriptors():
            players.append({
                "name": descriptor["name"],
                "provided_by": descriptor["provided_by"],
                "systemd_service": descriptor["systemd_service"],
                "icon_url": f"/api/v1/players/icon/{descriptor['icon']}",
                "allow_change": descriptor.get("allow_change", True),
                "maintainer_name": descriptor.get("maintainer_name", ""),
                "maintainer_url": descriptor.get("maintainer_url", ""),
                "settings": self._settings_with_values(descriptor),
            })
        return players

    def handle_list_players(self):
        """List all external players registered via drop-in descriptors."""
        return jsonify({"status": "success", "data": {"players": self._build_players()}})
```

Then update `handle_player_icon` to use `self.icons_dir` instead of the module `ICONS_DIR` constant (replace `icon_path = os.path.join(ICONS_DIR, f"{name}.svg")` with `icon_path = os.path.join(self.icons_dir, f"{name}.svg")`).

In `server.py` line 75, pass the configdb:

```python
        self.player_registry_handler = PlayerRegistryHandler(self.configdb)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/configurator/configurator && python3 -m pytest tests/ -v`
Expected: PASS (all Task 1 + Task 2 tests).

- [ ] **Step 5: Commit**

```bash
cd packages/configurator/configurator
git add configurator/handlers/player_registry_handler.py configurator/server.py tests/test_player_registry_listing.py
git commit -m "feat(players): include settings schema + current values in /api/v1/players"
```

---

### Task 3: configurator — `PUT /api/v1/players/<service>/settings`

Persist submitted setting values, validated against the plugin's declared schema.

**Files:**
- Modify: `packages/configurator/configurator/configurator/handlers/player_registry_handler.py`
- Modify: `packages/configurator/configurator/configurator/server.py` (register the route near the existing `/api/v1/players` routes, ~line 513)
- Test: `packages/configurator/configurator/tests/test_player_settings_write.py`

**Interfaces:**
- Consumes: `serialize_setting_value`, `setting_value_key`, `sanitize_settings` (Task 1); `ConfigDB.set` / `ConfigDB.get`.
- Produces:
  - `PlayerRegistryHandler.set_player_settings(self, systemd_service: str, values: dict) -> tuple[list[str], list[str]]` returning `(applied_keys, errors)`.
  - `PlayerRegistryHandler.handle_set_player_settings(self, systemd_service: str)` — Flask wrapper reading `request.get_json()`.

- [ ] **Step 1: Write the failing test**

Create `packages/configurator/configurator/tests/test_player_settings_write.py`:

```python
import json
import os
from configurator.handlers.player_registry_handler import PlayerRegistryHandler
from configurator.configdb import ConfigDB


def _setup(tmp_path):
    players_d = tmp_path / "players.d"
    os.makedirs(str(players_d), exist_ok=True)
    with open(os.path.join(str(players_d), "analog.json"), "w") as f:
        json.dump({
            "name": "Analog Input",
            "provided_by": "analog-recognition",
            "systemd_service": "analog-recognition",
            "icon": "analog",
            "settings": [
                {"key": "songrec_enabled", "type": "toggle",
                 "label": "Recognize tracks", "default": True},
            ],
        }, f)
    configdb = ConfigDB(db_path=str(tmp_path / "config.sqlite"))
    handler = PlayerRegistryHandler(configdb=configdb, players_d_dir=str(players_d))
    return handler, configdb


def test_set_player_settings_writes_namespaced_key(tmp_path):
    handler, configdb = _setup(tmp_path)
    applied, errors = handler.set_player_settings("analog-recognition", {"songrec_enabled": False})
    assert applied == ["songrec_enabled"]
    assert errors == []
    assert configdb.get("player.analog-recognition.songrec_enabled") == "false"


def test_set_player_settings_rejects_unknown_key(tmp_path):
    handler, _ = _setup(tmp_path)
    applied, errors = handler.set_player_settings("analog-recognition", {"nope": True})
    assert applied == []
    assert any("nope" in e for e in errors)


def test_set_player_settings_unknown_service(tmp_path):
    handler, _ = _setup(tmp_path)
    applied, errors = handler.set_player_settings("does-not-exist", {"x": 1})
    assert applied == []
    assert errors
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/configurator/configurator && python3 -m pytest tests/test_player_settings_write.py -v`
Expected: FAIL — `AttributeError: 'PlayerRegistryHandler' object has no attribute 'set_player_settings'`.

- [ ] **Step 3: Write minimal implementation**

Add to `PlayerRegistryHandler` in `player_registry_handler.py`:

```python
    def set_player_settings(self, systemd_service, values):
        """Validate and persist setting values for one plugin.

        Returns (applied_keys, errors)."""
        descriptor = next(
            (d for d in self._load_descriptors() if d["systemd_service"] == systemd_service),
            None,
        )
        if descriptor is None:
            return [], [f"unknown player service: {systemd_service}"]

        allowed = {s["key"]: s for s in sanitize_settings(descriptor)}
        applied, errors = [], []
        for key, value in (values or {}).items():
            setting = allowed.get(key)
            if setting is None:
                errors.append(f"unknown setting: {key}")
                continue
            self.configdb.set(
                setting_value_key(systemd_service, key),
                serialize_setting_value(setting["type"], value),
            )
            applied.append(key)
        return applied, errors

    def handle_set_player_settings(self, systemd_service):
        """Flask handler: persist submitted player settings."""
        values = request.get_json(silent=True) or {}
        applied, errors = self.set_player_settings(systemd_service, values)
        if not applied and errors:
            return jsonify({"status": "error", "message": "; ".join(errors)}), 400
        return jsonify({"status": "success",
                        "data": {"applied": applied, "errors": errors}})
```

At the top of the file, extend the Flask import guard to include `request`:

```python
try:
    from flask import jsonify, make_response, request
except ImportError:
    jsonify = None
    make_response = None
    request = None
```

In `server.py`, next to the existing `/api/v1/players` routes (around line 513–521), add:

```python
        @self.app.route('/api/v1/players/<systemd_service>/settings', methods=['PUT', 'POST'])
        def set_player_settings(systemd_service):
            """Persist settings for an external player plugin"""
            return self.player_registry_handler.handle_set_player_settings(systemd_service)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/configurator/configurator && python3 -m pytest tests/ -v`
Expected: PASS (all configurator tests).

- [ ] **Step 5: Commit**

```bash
cd packages/configurator/configurator
git add configurator/handlers/player_registry_handler.py configurator/server.py tests/test_player_settings_write.py
git commit -m "feat(players): PUT /api/v1/players/<service>/settings to persist plugin settings"
```

---

### Task 4: hbos-ui — API types + save function

**Files:**
- Modify: `packages/webui/hbos-ui/src/api/config.ts`
- Test: `packages/webui/hbos-ui/src/api/__tests__/playerSettings.test.ts`

**Interfaces:**
- Consumes: `useAppConfigStore` from `@/stores/appconfig` (already imported in `config.ts`); `configStore.getConfigApiBaseUrl()`.
- Produces:
  - `interface PlayerSetting { key: string; type: 'toggle' | 'select'; label: string; description?: string; default: boolean | string; value: boolean | string; options?: { value: string; label: string }[] }`
  - `ExternalPlayer.settings?: PlayerSetting[]`
  - `saveExternalPlayerSettings(systemdService: string, values: Record<string, boolean | string>): Promise<void>`

- [ ] **Step 1: Write the failing test**

Create `packages/webui/hbos-ui/src/api/__tests__/playerSettings.test.ts`:

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('@/stores/appconfig', () => ({
  useAppConfigStore: () => ({ getConfigApiBaseUrl: () => 'http://host/api/v1' }),
}))

import { saveExternalPlayerSettings } from '@/api/config'

describe('saveExternalPlayerSettings', () => {
  beforeEach(() => { vi.restoreAllMocks() })

  it('PUTs values to the player settings endpoint', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ ok: true, json: async () => ({}) })
    vi.stubGlobal('fetch', fetchMock)

    await saveExternalPlayerSettings('analog-recognition', { songrec_enabled: false })

    expect(fetchMock).toHaveBeenCalledWith(
      'http://host/api/v1/players/analog-recognition/settings',
      expect.objectContaining({
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ songrec_enabled: false }),
      }),
    )
  })

  it('throws on a non-ok response', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 500 }))
    await expect(
      saveExternalPlayerSettings('analog-recognition', { songrec_enabled: true }),
    ).rejects.toThrow()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/webui/hbos-ui && npx vitest run src/api/__tests__/playerSettings.test.ts`
Expected: FAIL — `saveExternalPlayerSettings` is not exported.

- [ ] **Step 3: Write minimal implementation**

In `packages/webui/hbos-ui/src/api/config.ts`, add the `PlayerSetting` interface immediately above `export interface ExternalPlayer {`, add `settings` to `ExternalPlayer`, and add the save function after `getExternalPlayers`:

```typescript
export interface PlayerSetting {
  key: string
  type: 'toggle' | 'select'
  label: string
  description?: string
  default: boolean | string
  value: boolean | string
  options?: { value: string; label: string }[]
}
```

Add to the `ExternalPlayer` interface body:

```typescript
  settings?: PlayerSetting[]
```

Add after the `getExternalPlayers` function:

```typescript
/**
 * Persist settings for an external player plugin.
 */
export const saveExternalPlayerSettings = async (
  systemdService: string,
  values: Record<string, boolean | string>,
): Promise<void> => {
  const configStore = useAppConfigStore()
  const baseUrl = configStore.getConfigApiBaseUrl()
  const response = await fetch(`${baseUrl}/players/${systemdService}/settings`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(values),
  })
  if (!response.ok) {
    throw new Error(`Failed to save player settings: ${response.status}`)
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/webui/hbos-ui && npx vitest run src/api/__tests__/playerSettings.test.ts`
Expected: PASS (2 passed).

- [ ] **Step 5: Commit**

```bash
cd packages/webui/hbos-ui
git add src/api/config.ts src/api/__tests__/playerSettings.test.ts
git commit -m "feat(players): API types and save function for plugin settings"
```

---

### Task 5: hbos-ui — carry settings through `players.vue` + save wiring

**Files:**
- Modify: `packages/webui/hbos-ui/src/views/services/players.vue`

**Interfaces:**
- Consumes: `getExternalPlayers`, `saveExternalPlayerSettings`, `PlayerSetting` (Task 4).
- Produces: the `Player` interface in `players.vue` gains `settings?: PlayerSetting[]`; a handler `updateExternalSetting(playerName: string, key: string, value: boolean | string)`; `saveConfig` branches for external players.

This task has no unit test (it is view-level glue verified end-to-end in the framework verification and the analog-recognition plan). Its correctness gate is the typecheck + the PlayerCard component test in Task 6.

- [ ] **Step 1: Add `settings` to the `Player` interface**

In `players.vue`, add to the `interface Player { … }` block:

```typescript
  settings?: import('@/api/config').PlayerSetting[]
```

- [ ] **Step 2: Copy settings through the external-player merge**

In `loadServiceStatus`, in the `players.value.push({ … })` for external players, add:

```typescript
          settings: ext.settings,
```

- [ ] **Step 3: Import the save function**

Add `saveExternalPlayerSettings` to the existing import from `@/api/config`:

```typescript
import {
  getMultipleServiceStatus,
  enableNowService,
  disableNowService,
  checkSystemdServiceExists,
  getExternalPlayers,
  saveExternalPlayerSettings,
} from '@/api/config'
```

- [ ] **Step 4: Add the setting-update handler**

Add near `updateAirplayVersion`:

```typescript
const updateExternalSetting = (playerName: string, key: string, value: boolean | string) => {
  const player = players.value[findPlayerIndex(playerName)]
  if (!player?.settings) return
  const setting = player.settings.find(s => s.key === key)
  if (setting) setting.value = value
}
```

- [ ] **Step 5: Branch `saveConfig` for external players**

In the existing `saveConfig(playerName)` function, add at the top (before any built-in handling):

```typescript
  const player = players.value[findPlayerIndex(playerName)]
  if (player?.isExternal && player.settings?.length) {
    const values: Record<string, boolean | string> = {}
    for (const s of player.settings) values[s.key] = s.value
    try {
      await saveExternalPlayerSettings(player.systemdService, values)
    } catch (e) {
      player.error = e instanceof Error ? e.message : 'Failed to save settings'
    }
    toggleConfigExpanded(playerName)
    return
  }
```

- [ ] **Step 6: Wire the new emit in both `<PlayerCard>` usages**

In the template, add to **both** `<PlayerCard … />` (built-in list and external list):

```html
          @update-external-setting="(key, value) => updateExternalSetting(player.name, key, value)"
```

- [ ] **Step 7: Typecheck**

Run: `cd packages/webui/hbos-ui && npx vue-tsc --noEmit`
Expected: no errors from `players.vue` (pre-existing unrelated errors, if any, are out of scope — confirm none reference `players.vue`).

- [ ] **Step 8: Commit**

```bash
cd packages/webui/hbos-ui
git add src/views/services/players.vue
git commit -m "feat(players): carry plugin settings through players view and save wiring"
```

---

### Task 6: hbos-ui — generic settings rendering in `PlayerCard.vue`

**Files:**
- Modify: `packages/webui/hbos-ui/src/components/PlayerCard.vue`
- Test: `packages/webui/hbos-ui/src/components/__tests__/PlayerCard.settings.test.ts`

**Interfaces:**
- Consumes: the `Player` prop; `ToggleSwitch` (already imported); emits `update-external-setting`, `save-config`, `cancel-config`, `toggle-config`.
- Produces: `hasConfig` also true for external players with settings; a generic settings section; a new emit `'update-external-setting': [key: string, value: boolean | string]`.

- [ ] **Step 1: Write the failing test**

Create `packages/webui/hbos-ui/src/components/__tests__/PlayerCard.settings.test.ts`:

```typescript
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import PlayerCard from '@/components/PlayerCard.vue'

const externalPlayer = {
  name: 'Analog Input',
  providedBy: 'analog-recognition',
  systemdService: 'analog-recognition',
  config: 'none',
  status: 'inactive',
  icon: 'analog',
  enabled: false,
  exists: true,
  isExternal: true,
  settings: [
    { key: 'songrec_enabled', type: 'toggle', label: 'Recognize tracks',
      default: true, value: true },
  ],
}

describe('PlayerCard generic settings', () => {
  it('renders a config caret for an external player that has settings', () => {
    const wrapper = mount(PlayerCard, {
      props: { player: externalPlayer, isExpanded: false },
      global: { stubs: { Icon: true, InlineSvg: true, ToggleSwitch: true } },
    })
    expect(wrapper.find('.expand-caret').exists()).toBe(true)
  })

  it('emits update-external-setting when a toggle setting changes', async () => {
    const wrapper = mount(PlayerCard, {
      props: { player: externalPlayer, isExpanded: true },
      global: { stubs: { Icon: true, InlineSvg: true } },
    })
    const toggle = wrapper.findComponent({ name: 'ToggleSwitch' })
    toggle.vm.$emit('update:modelValue', false)
    await wrapper.vm.$nextTick()
    expect(wrapper.emitted('update-external-setting')?.[0]).toEqual(['songrec_enabled', false])
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/webui/hbos-ui && npx vitest run src/components/__tests__/PlayerCard.settings.test.ts`
Expected: FAIL — no `.expand-caret` for the external player (hasConfig false), and no `update-external-setting` emit.

- [ ] **Step 3: Write minimal implementation**

In `PlayerCard.vue`:

a) Extend `hasConfig`:

```typescript
const hasConfig = computed(() => {
  if (props.player.isExternal) {
    return (props.player.settings?.length ?? 0) > 0
  }
  return (props.player.name === 'Airplay' || props.player.name === 'TOSLink') &&
         typeof props.player.config === 'object'
})
```

b) Add `update-external-setting` to `defineEmits`:

```typescript
defineEmits<{
  toggle: []
  'toggle-config': []
  'navigate-bluetooth': []
  'update-airplay-version': [version: number]
  'update-toslink-sensitivity': [sensitivity: string]
  'update-external-setting': [key: string, value: boolean | string]
  'cancel-config': []
  'save-config': []
}>()
```

c) Add `settings` to the local `Player` interface in PlayerCard (mirror api types):

```typescript
  isExternal?: boolean
  settings?: { key: string; type: 'toggle' | 'select'; label: string; description?: string; default: boolean | string; value: boolean | string; options?: { value: string; label: string }[] }[]
```

d) Add a generic config section in the template, immediately after the existing TOSLink config `<div>` block:

```html
      <!-- Generic external-plugin settings -->
      <div v-if="player.isExternal && (player.settings?.length ?? 0) > 0" class="config-section">
        <div v-if="isExpanded" class="config-content">
          <div class="config-form">
            <label v-for="setting in player.settings" :key="setting.key" class="config-option">
              {{ setting.label }}
              <ToggleSwitch
                v-if="setting.type === 'toggle'"
                :model-value="setting.value === true"
                @update:model-value="(v) => $emit('update-external-setting', setting.key, v)"
              />
              <select
                v-else-if="setting.type === 'select'"
                :value="setting.value"
                @change="$emit('update-external-setting', setting.key, ($event.target as HTMLSelectElement).value)"
                class="version-select"
              >
                <option v-for="opt in setting.options" :key="opt.value" :value="opt.value">
                  {{ opt.label }}
                </option>
              </select>
            </label>
          </div>
          <div class="config-actions">
            <button class="config-btn config-btn--cancel" @click="$emit('cancel-config')">Cancel</button>
            <button class="config-btn config-btn--save" @click="$emit('save-config')">Save</button>
          </div>
        </div>
      </div>
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/webui/hbos-ui && npx vitest run src/components/__tests__/PlayerCard.settings.test.ts`
Expected: PASS (2 passed).

- [ ] **Step 5: Typecheck + full test run**

Run: `cd packages/webui/hbos-ui && npx vue-tsc --noEmit && npx vitest run`
Expected: no new type errors; all tests pass.

- [ ] **Step 6: Commit**

```bash
cd packages/webui/hbos-ui
git add src/components/PlayerCard.vue src/components/__tests__/PlayerCard.settings.test.ts
git commit -m "feat(players): generic settings rendering for external plugins in PlayerCard"
```

---

## End-to-end verification (on device `matuschd@192.168.11.136`)

After both repos are rebuilt and installed (configurator + webui debs), or run in dev, use a throwaway descriptor to prove the framework before the analog plugin exists:

1. Write `/etc/hifiberry/players.d/dummy.json` with a `settings` array containing one `toggle` (systemd_service pointing at any existing user unit, e.g. `squeezelite`, so the row renders).
2. `curl -s localhost:1081/api/v1/players | jq '.data.players[] | select(.provided_by=="squeezelite") | .settings'` → shows the toggle with its `value` (default).
3. `curl -X PUT -H 'Content-Type: application/json' -d '{"<key>":false}' localhost:1081/api/v1/players/squeezelite/settings` → `{"status":"success",...}`.
4. `curl -s localhost:1081/api/v1/key/player.squeezelite.<key>` → `"false"`.
5. In the webui Players view, expand that plugin: the toggle renders, flipping + Save persists (re-fetch shows the new value).
6. Remove the throwaway descriptor.

## Self-review notes

- Spec section C1 (schema) → Task 1 `sanitize_settings` + Task 4 `PlayerSetting`. C2 (list enrich + PUT) → Tasks 2–3. C3 (webui types/view/PlayerCard) → Tasks 4–6. Covered.
- Namespacing `player.<service>.<key>` is defined once in `setting_value_key` (Task 1) and reused in Tasks 2 and 3 — no drift.
- `update-external-setting` emit name is identical in PlayerCard (Task 6), the two template usages (Task 5 Step 6), and the handler `updateExternalSetting` (Task 5) — consistent.

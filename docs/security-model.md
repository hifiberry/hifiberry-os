# HiFiBerryOS Security Model

HiFiBerryOS runs several daemons that expose HTTP/REST APIs (configuration,
player control, DSP, room correction, …). Historically these listened on the
network with no authentication. The security model adds a single
authentication/authorization layer in front of all of them so that:

- **Everyday music use never needs a password** — playback, volume, browsing
  the library, switching players.
- **Risky operations require a password** — changing system settings, network,
  installing software, factory reset, recording from a microphone, etc.
- The user can tighten this to *require a password for everything*, loosen it to
  *no password at all*, or leave the default (password for risky operations
  only).

Related: [Backend APIs](backend-apis.md) describes the services and nginx
routing this model sits in front of.

## Architecture

Everything is reverse-proxied through **nginx on port 80**. Nginx is the single
front door; each backend binds to `127.0.0.1` so it cannot be reached directly
from the network. A small service, **`hifiberry-auth`**, decides whether each
request is allowed.

```
                    ┌───────────────────────── device ──────────────────────────┐
  browser ── :80 ──▶│ nginx                                                       │
                    │   │  auth_request ──▶ hifiberry-auth (127.0.0.1:1089)       │
                    │   │                     · classifies the request (ok/risky) │
                    │   │                     · checks policy + session           │
                    │   │                     · 200 allow / 401 deny (+ hint)     │
                    │   ▼ (on 200)                                                 │
                    │  config-server 1081 · audiocontrol 1080 · pipewire 2716 …   │
                    └─────────────────────────────────────────────────────────────┘
```

nginx uses the [`auth_request`](https://nginx.org/en/docs/http/ngx_http_auth_request_module.html)
module. Before proxying an `/api/<service>/` request to its backend, nginx makes
an internal subrequest to `hifiberry-auth`. If that subrequest returns `200` the
request proceeds; if it returns `401` nginx blocks it and returns `401` to the
browser with a hint about what to do next.

**Key property:** authorization is enforced at the gateway, not in each backend.
Backends do not implement auth; they rely on binding to localhost + the gateway
being the only reachable door.

## The `hifiberry-auth` service

The `hifiberry-auth` package provides the gateway backend.

| | |
|---|---|
| Listens on | `127.0.0.1:1089` (localhost only) |
| Runs as | `_hifiauth` (system user, `NoNewPrivileges`, `ProtectSystem=strict`, empty capability set) |
| State | SQLite DB at `/var/lib/hifiberry-auth/auth.db` (mode `0750`) |
| Manifests | `/etc/hifiberry/auth.d/*.json` |
| systemd unit | `hifiberry-auth.service` |
| Implementation | Python (Flask + Waitress) |

It exposes three kinds of endpoint: the internal nginx verify endpoint, the
public auth API (`/api/auth/...`), and nothing else.

## Tiers: `ok` vs `risky`

Every request resolves to one of two tiers:

- **`ok`** — everyday, non-destructive, music-related actions. Never require a
  password (unless the policy is `all`).
- **`risky`** — actions that can change the system, affect security/privacy, or
  destroy data. Require authentication (unless the policy is `off`).

### Classification principle

- **Audio / DSP is `ok`.** PipeWire (speaker EQ, input-processor, routing,
  volume, graph), playback transport, volume, library browsing, and player
  lifecycle (start/stop/kill/enable/disable) are everyday music use.
- **System / security / privacy is `risky`.** Reboot, hostname/network, factory
  reset, extension/software install, credential-exposing endpoints, and starting
  a microphone recording (an unauthenticated network client should not be able
  to record the room).
- **When in doubt, `risky`.** Any request that no manifest classifies falls back
  to `risky` — fail safe.

## Protection policy

A single device-wide setting controls how much the tiers are enforced:

| Policy | `ok` requests | `risky` requests | Meaning |
|---|---|---|---|
| `unset` | allowed | prompt to **set a password** | First boot — no password chosen yet |
| `off`   | allowed | allowed | No password required for anything |
| `risky` | allowed | require sign-in | **Default** — password protects settings only |
| `all`   | require sign-in | require sign-in | Password required for the whole UI |

The default after a password is set is `risky`. The user chooses the policy in
the setup wizard and can change it later under **Settings → Security**.

## Sessions, password, and CSRF

- **Password** is hashed with **argon2id** and stored in the SQLite DB. It is
  never stored in the browser.
- **Session** is an **HMAC-SHA256-signed cookie** (`hifiberry_session`,
  `HttpOnly`, `SameSite=Lax`) carrying its own issue/expiry timestamps, a CSRF
  token and a random session id, signed with a per-device key. The session id
  is also recorded in an **allowlist table** in the SQLite DB: a cookie is
  accepted only while its row is there. Signing out deletes that one row;
  changing the device password deletes every row and then mints a new session
  for whoever changed it, so every *other* device is signed out. Rotating the
  key (or deleting the DB) still revokes every session. Sessions issued before
  0.2.0 carry no session id and are not accepted, so every device signs in once
  after that upgrade.
- **Session lifetime**: **12 hours** by default, **30 days** if the user ticks
  *“stay signed in on this device”*.
- **CSRF**: every risky **non-GET** request must carry the session's CSRF token
  in the `X-CSRF-Token` header. GET requests do not (they are safe/idempotent).
  The token lives only in memory in the web UI; after a page reload it is
  silently re-fetched from the still-valid session (`GET /api/auth/csrf`) rather
  than re-prompting for the password.

No `Secure` flag is set on the cookie because HiFiBerryOS is served over plain
HTTP on the local network.

## The decision matrix

For each request, `hifiberry-auth` resolves `(method, tier, policy, session)` to
allow or deny:

1. `tier == ok` and `policy != all` → **allow (200)**
2. `tier == risky` and `policy == off` → **allow (200)**
3. `tier == risky` and `policy == unset` → **deny (401, hint `set-password`)**
4. otherwise a valid session is required:
   - no session → **deny (401, hint `login`)**
   - session present, non-GET, missing/invalid CSRF → **deny (401, hint `login`)**
   - session present (and CSRF valid for non-GET) → **allow (200)**
5. `policy == all` gates `ok` requests too (they fall through to step 4).

On a `401`, the gateway sets a `WWW-Authenticate-Hint` response header of
`set-password` or `login` so the web UI knows whether to show the “create a
password” or the “sign in” prompt.

## Classification manifests

Which endpoints are `ok` vs `risky` is data, not code. **Each package ships a
drop-in manifest** describing its own endpoints into `/etc/hifiberry/auth.d/`.
`hifiberry-auth` aggregates them at startup.

### Format

```json
{
  "service": "config",
  "match_prefix": "/api/config/v1",
  "default_tier": "risky",
  "rules": [
    { "tier": "ok", "methods": ["GET"],  "paths": ["/version", "/systeminfo", "/soundcard/detect-live"] },
    { "tier": "ok", "methods": ["POST"], "paths": ["/systemd/service/*/*"] },
    { "tier": "risky", "methods": ["*"], "paths": ["/**"] }
  ]
}
```

- **`match_prefix`** — a request is routed to the manifest whose `match_prefix`
  is the **longest prefix** of the request path. The remainder is matched against
  that manifest's rules. Note the prefix is the *browser-facing* path (before
  nginx strips it), e.g. `/api/pipewire` even though the backend sees `/api/v1/...`.
- **`rules`** are evaluated in order, first hit wins. A rule matches when the
  method is in `methods` (or `methods` contains `*`) and the path remainder
  matches one of `paths`.
- **Path globs**: `*` matches exactly one path segment; `**` matches the rest of
  the path (including nothing), and must be last.
- **`default_tier`** applies when no rule matches. A request under no manifest at
  all resolves to `risky`.
- A malformed manifest is skipped (logged) rather than failing the whole gate.

### Manifests shipped by each package

| Package | File | `match_prefix` | Default | Notes |
|---|---|---|---|---|
| hifiberry-configurator | `config.json` | `/api/config/v1` | risky | reads, systemd status, player & volume control are `ok` |
| hifiberry-audiocontrol | `audiocontrol-auth.json` | `/api/audiocontrol` | risky | now-playing/metadata/library reads + transport/volume/favourites are `ok` |
| pipewire-api | `pipewire.json` | `/api/pipewire` | **ok** | pure audio/DSP — the whole service is `ok` |
| roomeq | `roomeq.json` | `/api/roomeq` | risky | reads + test-signal generation `ok`; mic recording & applying correction `risky` |

Packages that don't ship a manifest are `risky` by default for their whole API.

## First-boot setup

The setup wizard includes a **“Secure your device”** step where the user sets the
password and chooses the protection scope (protect settings only, or require the
password for everything). Setting the password there establishes a session, so
the configuration writes performed when finishing setup (hostname, sound card,
mark-setup-complete) are authenticated without a second prompt.

Read-only setup endpoints (e.g. `GET /api/config/v1/soundcard/detect-live`) are
classified `ok` so the wizard's hardware detection works before any password
exists.

## Web UI integration

- **`apiFetch`** wraps every risky-capable API call. It sends the session cookie,
  attaches `X-CSRF-Token` on non-GET requests, and on a `401` reads the
  `WWW-Authenticate-Hint` to show the right prompt, then retries once.
- **`SecurityPrompt`** is the modal shown on demand: “create a password” (first
  risky action, policy `unset`) or “sign in” (session expired/absent).
- **Settings → Security** shows the current state (protection, password set,
  session) and lets the user set/change the password, choose the policy, or turn
  protection off.
- Music playback, volume, and library browsing go through `ok` endpoints and
  therefore never trigger a prompt.

## Auth API reference (`/api/auth/`)

These endpoints are always reachable (nginx sets `auth_request off` for them),
so the writes among them check the CSRF token themselves rather than relying on
the gateway:

| Endpoint | Method | Purpose |
|---|---|---|
| `/api/auth/status` | GET | Current `{protection, has_password, authenticated}` |
| `/api/auth/set-password` | POST | Set/change the password (needs `current` when one exists); mints a session |
| `/api/auth/login` | POST | Sign in with the password (rate-limited); mints a session |
| `/api/auth/logout` | POST | End the session (requires a session + CSRF token); clears the cookie only when it succeeds |
| `/api/auth/policy` | POST | Set the protection policy (`off`/`risky`/`all`); requires a session + CSRF token |
| `/api/auth/csrf` | GET | Return the current session's CSRF token (used to rehydrate after reload) |

The internal `GET /_auth/verify` endpoint is the nginx subrequest target; it is
not reachable from the browser.

## Files and operations

| Path | Purpose |
|---|---|
| `/var/lib/hifiberry-auth/auth.db` | password hash, signing key, protection policy, session allowlist |
| `/etc/hifiberry/auth.d/*.json` | per-service classification manifests |
| `/etc/nginx/hifiberry-auth.d/00-verify.conf` | server-level `auth_request` wiring |
| `/etc/nginx/hifiberry-api.d/hifiberry-auth.nginx` | the `/api/auth/` location |

Common operations:

- **Reset the password / all sessions**: stop the service, delete
  `/var/lib/hifiberry-auth/auth.db`, start the service. Protection returns to
  `unset` and every session is revoked, since the allowlist lives in that file.
- **Reload manifests**: manifests are read at startup, so
  `systemctl restart hifiberry-auth` after adding or changing one.
- **Disable the gate entirely**: set the policy to `off`, or (for
  troubleshooting) remove/stop the `hifiberry-auth` package — without the verify
  snippet nginx does no gating.

## Threat model and limitations

- The gateway is only effective while backends are **not** reachable directly on
  the network. Each backend must bind to `127.0.0.1`; a backend still bound to
  `0.0.0.0` can be reached around the gateway. Binding backends to localhost is
  part of this model and is being rolled out per service.
- Traffic is plain HTTP on the LAN — the model protects against unauthenticated
  API use, not against a network attacker who can read/modify traffic. It assumes
  a trusted local network.
- Music-streaming daemons that speak their own network protocols (AirPlay,
  Spotify Connect, Roon, Bluetooth, …) are out of scope; they are not HTTP APIs
  behind nginx and have their own pairing/auth mechanisms.

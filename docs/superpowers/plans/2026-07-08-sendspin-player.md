# Sendspin Player Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a HiFiBerryOS Sendspin player — a C++ daemon that renders Music Assistant's Sendspin stream to the HiFiBerry card, reports metadata/state to audiocontrol (ACR), and forwards transport commands back to MA — packaged as a plugin-type deb like shairport.

**Architecture:** A new standalone repo `github.com/hifiberry/sendspin` holds a C++ daemon (`sendspind`) wrapping the `sendspin-cpp` library plus its own Debian packaging. A small ACR change gives the generic player an outbound `command_url`. This hifiberry-os repo gets a thin `packages/sendspin/build.sh` that clones and builds the new repo (acr/configurator pattern).

**Tech Stack:** C++17, CMake (FetchContent for `sendspin-cpp`), ALSA (`libasound2`), `snd_mixer`, libcurl (ACR POST), `dns_sd` (`libavahi-compat-libdnssd`) for mDNS, `nlohmann/json` (daemon-side JSON), CTest (plain-assert unit tests). ACR side: Rust, `ureq`.

## Global Constraints

- **Audio PCM output device is ALSA `default`** (PipeWire bridge) — never `hw:`.
- **Volume rides the ALSA mixer control from `config-soundcard`** on `hw:<index>` — the same control ACR's global volume monitors (on the reference device: `Digital` / `hw:0`).
- **Device discovery happens in the systemd start wrapper** (`start-sendspin.sh`), not compiled in — like `start-shairport.sh` / `start-librespot.sh`.
- **Runs as a systemd *user* service** under the `/etc/hifiberry.user` account, `After=pipewire.service`, guarded by `config-soundcard --detect`, `WantedBy=default.target` — exactly like `shairport`/`librespot`.
- **Advertised Sendspin name = the pretty hostname** (`hostnamectl hostname --pretty`, fallback `hostname`, fallback `HiFiBerry`).
- **Command port constant is 3547.** The wrapper passes `--command-port 3547`; `players.d/sendspin.json` hard-codes `http://127.0.0.1:3547/command`.
- **Sendspin controller has no SEEK.** Forwarded transport commands are exactly: `play`, `pause`, `stop`, `next`, `previous`. `seek` is not a capability.
- **Sendspin volume is `uint8_t` 0–255.**
- **ACR `command_url` must be backward-compatible:** absent → unchanged behaviour for all other generic players.
- **`sendspin-cpp` is pinned** to `GIT_REPOSITORY https://github.com/Sendspin/sendspin-cpp.git`, `GIT_TAG bf9e085`.
- Never install via pip; deb packages only. **No `Co-Authored-By` in commits** (project CLAUDE.md).

## File Structure

**New repo `sendspin/`** (developed in-place at `packages/sendspin/sendspin`, its own git repo, gitignored by the parent; pushed to `github.com/hifiberry/sendspin`):

```
CMakeLists.txt              # top-level: FetchContent sendspin-cpp, find ALSA/curl/dns_sd/json, build sendspind + tests
src/
  options.h  options.cpp    # CLI parsing -> Options struct (pure)
  song.h                    # Song struct (shared by report_json + metadata_map)
  volume_scale.h volume_scale.cpp   # 0-255 <-> raw mixer range (pure)
  report_json.h report_json.cpp     # build ACR update JSON (pure)
  command_map.h command_map.cpp     # command JSON -> SendspinControllerCommand (pure)
  http_request.h http_request.cpp   # minimal HTTP request parse (pure)
  metadata_map.h metadata_map.cpp   # ServerMetadataStateObject -> Song (pure)
  alsa_sink.h alsa_sink.cpp         # ALSA "default" PCM output (integration)
  volume_control.h volume_control.cpp   # snd_mixer get/set/monitor (integration)
  acr_reporter.h acr_reporter.cpp   # libcurl POST + background queue (integration)
  command_server.h command_server.cpp   # socket HTTP listener (integration)
  mdns.h mdns.cpp           # DNSServiceRegister advertiser (integration)
  listeners.h listeners.cpp # PlayerRole/Metadata/Controller listener impls (integration)
  main.cpp                  # arg parse, wire, main loop (integration)
scripts/start-sendspin.sh   # systemd wrapper: discovery + exec sendspind
tests/
  test_options.cpp test_volume_scale.cpp test_report_json.cpp
  test_command_map.cpp test_http_request.cpp test_metadata_map.cpp
  test_alsa_format.cpp
debian/
  changelog control compat rules copyright
  sendspin.install sendspin.dirs sendspin.postinst sendspin.postrm
data/
  usr/lib/systemd/user/sendspin.service
  etc/hifiberry/players.d/sendspin.json
  etc/hifiberry/players.d/icons/sendspin.svg
  etc/configserver/conf.d/sendspin.json
  etc/audiocontrol/players.d/sendspin.json
build.sh                    # repo's own build (sbuild -> .deb)
.gitignore
README.md
```

**ACR repo** (`packages/acr/acr`, its own git repo, branch `main`): modify `src/players/generic/generic_controller.rs`, add test in `src/players/generic/tests.rs`, bump `Cargo.toml` + `debian/changelog` to 0.7.15.

**hifiberry-os repo** (this repo): create `packages/sendspin/build.sh`, `packages/sendspin/clean.sh`, add `.gitignore` entry.

**Build/test environment:** all C++ builds + tests run on the arm64 build host `192.168.1.112` (user `matuschd`); on-device integration on tannoy `192.168.1.12`. macOS has no ALSA — do not attempt to build the daemon locally.

---

### Task 1: New repo scaffold — CMake + minimal daemon + CTest

**Files:**
- Create: `packages/sendspin/sendspin/.gitignore`
- Create: `packages/sendspin/sendspin/CMakeLists.txt`
- Create: `packages/sendspin/sendspin/src/main.cpp`
- Create: `packages/sendspin/sendspin/README.md`

**Interfaces:**
- Produces: a `sendspind` executable that responds to `--version`; a CMake project that links `sendspin`, `ALSA`, `CURL`, `nlohmann_json`, and dns_sd, with `enable_testing()` + a `tests/` subdir (populated by later tasks).

- [ ] **Step 1: Create the repo and gitignore**

```bash
mkdir -p packages/sendspin/sendspin/src packages/sendspin/sendspin/tests
cd packages/sendspin/sendspin
git init -q
cat > .gitignore <<'EOF'
/build/
*.deb
*.buildinfo
*.changes
EOF
```

- [ ] **Step 2: Write `CMakeLists.txt`**

```cmake
cmake_minimum_required(VERSION 3.16)
project(sendspind VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)

# sendspin-cpp: player + controller + metadata roles only (slim the binary)
set(SENDSPIN_ENABLE_COLOR OFF CACHE BOOL "" FORCE)
set(SENDSPIN_ENABLE_ARTWORK OFF CACHE BOOL "" FORCE)
set(SENDSPIN_ENABLE_VISUALIZER OFF CACHE BOOL "" FORCE)
set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
FetchContent_Declare(sendspin
  GIT_REPOSITORY https://github.com/Sendspin/sendspin-cpp.git
  GIT_TAG bf9e085)
FetchContent_MakeAvailable(sendspin)

find_package(ALSA REQUIRED)
find_package(CURL REQUIRED)
find_package(nlohmann_json REQUIRED)

# dns_sd from libavahi-compat-libdnssd
find_library(DNSSD_LIB NAMES dns_sd)
if(NOT DNSSD_LIB)
  message(FATAL_ERROR "libavahi-compat-libdnssd (dns_sd) not found")
endif()

add_library(sendspind_lib STATIC
  src/options.cpp src/volume_scale.cpp src/report_json.cpp
  src/command_map.cpp src/http_request.cpp src/metadata_map.cpp
  src/alsa_sink.cpp src/volume_control.cpp src/acr_reporter.cpp
  src/command_server.cpp src/mdns.cpp src/listeners.cpp)
target_include_directories(sendspind_lib PUBLIC src)
target_link_libraries(sendspind_lib PUBLIC
  sendspin ALSA::ALSA CURL::libcurl nlohmann_json::nlohmann_json ${DNSSD_LIB})

add_executable(sendspind src/main.cpp)
target_link_libraries(sendspind PRIVATE sendspind_lib)

enable_testing()
add_subdirectory(tests)
```

- [ ] **Step 3: Write a minimal `src/main.cpp`**

```cpp
#include <cstdio>
#include <cstring>

int main(int argc, char** argv) {
    for (int i = 1; i < argc; ++i) {
        if (std::strcmp(argv[i], "--version") == 0) {
            std::printf("sendspind 0.1.0\n");
            return 0;
        }
    }
    std::fprintf(stderr, "sendspind: nothing to do (try --version)\n");
    return 0;
}
```

- [ ] **Step 4: Write a placeholder `tests/CMakeLists.txt` and README**

```cmake
# tests/CMakeLists.txt — populated by later tasks
```

```markdown
# sendspin

HiFiBerryOS Sendspin player daemon. Renders Music Assistant's Sendspin stream to
the HiFiBerry sound card, reports metadata to audiocontrol, and forwards transport
commands back to Music Assistant. See docs in hifiberry-os.
```

Note: `src/main.cpp` and `CMakeLists.txt` reference source files created in later tasks. To let Task 1 build in isolation, temporarily comment out the `add_library(sendspind_lib ...)` block and its link in `sendspind` for this task's build check, then restore it in Task 2. (The controller subagent: build `sendspind` alone here; the lib comes online in Task 2.)

- [ ] **Step 5: Build + verify on the build host**

Run (from the build host `192.168.1.112`, in this repo's checkout):
```bash
cmake -S . -B build && cmake --build build --target sendspind -j4 && ./build/sendspind --version
```
Expected: configures, builds, prints `sendspind 0.1.0`.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "scaffold: sendspind CMake project + minimal main"
```

---

### Task 2: CLI options parser (pure)

**Files:**
- Create: `packages/sendspin/sendspin/src/options.h`
- Create: `packages/sendspin/sendspin/src/options.cpp`
- Test: `packages/sendspin/sendspin/tests/test_options.cpp`

**Interfaces:**
- Produces:
  ```cpp
  struct Options {
      std::string alsa_device = "default";
      std::string mixer_control;   // e.g. "Digital" / "Softvol"; may be empty
      std::string mixer_device = "hw:0";
      int command_port = 3547;
      std::string acr_url = "http://localhost:1080/api/player/sendspin/update";
      std::string name = "HiFiBerry";
      uint16_t sendspin_port = 8928;
  };
  Options parse_args(int argc, char** argv);  // throws std::runtime_error on unknown/malformed flag
  ```
  Flags: `--alsa-device`, `--mixer-control`, `--mixer-device`, `--command-port`, `--acr-url`, `--name`, `--sendspin-port`.

- [ ] **Step 1: Write the failing test**

```cpp
// tests/test_options.cpp
#include "options.h"
#include <cassert>
#include <cstring>
#include <string>

int main() {
    // Defaults when no args
    {
        char prog[] = "sendspind";
        char* argv[] = {prog, nullptr};
        Options o = parse_args(1, argv);
        assert(o.alsa_device == "default");
        assert(o.command_port == 3547);
        assert(o.sendspin_port == 8928);
    }
    // Parses provided values
    {
        char prog[] = "sendspind";
        char a1[] = "--mixer-control"; char v1[] = "Digital";
        char a2[] = "--mixer-device";  char v2[] = "hw:0";
        char a3[] = "--command-port";  char v3[] = "3547";
        char a4[] = "--name";          char v4[] = "Living Room";
        char* argv[] = {prog, a1, v1, a2, v2, a3, v3, a4, v4, nullptr};
        Options o = parse_args(9, argv);
        assert(o.mixer_control == "Digital");
        assert(o.mixer_device == "hw:0");
        assert(o.command_port == 3547);
        assert(o.name == "Living Room");
    }
    // Unknown flag throws
    {
        char prog[] = "sendspind"; char bad[] = "--nope";
        char* argv[] = {prog, bad, nullptr};
        bool threw = false;
        try { parse_args(2, argv); } catch (const std::exception&) { threw = true; }
        assert(threw);
    }
    return 0;
}
```

- [ ] **Step 2: Register the test and run to verify it fails**

Add to `tests/CMakeLists.txt`:
```cmake
add_executable(test_options test_options.cpp)
target_link_libraries(test_options PRIVATE sendspind_lib)
add_test(NAME options COMMAND test_options)
```
Run: `cmake -S . -B build && cmake --build build --target test_options`
Expected: FAIL to compile — `options.h` not found.

- [ ] **Step 3: Write `options.h` + `options.cpp`**

```cpp
// src/options.h
#pragma once
#include <cstdint>
#include <string>

struct Options {
    std::string alsa_device = "default";
    std::string mixer_control;
    std::string mixer_device = "hw:0";
    int command_port = 3547;
    std::string acr_url = "http://localhost:1080/api/player/sendspin/update";
    std::string name = "HiFiBerry";
    uint16_t sendspin_port = 8928;
};

Options parse_args(int argc, char** argv);
```

```cpp
// src/options.cpp
#include "options.h"
#include <stdexcept>
#include <string>

Options parse_args(int argc, char** argv) {
    Options o;
    auto need = [&](int& i) -> std::string {
        if (i + 1 >= argc) throw std::runtime_error(std::string("missing value for ") + argv[i]);
        return argv[++i];
    };
    for (int i = 1; i < argc; ++i) {
        std::string a = argv[i];
        if (a == "--alsa-device") o.alsa_device = need(i);
        else if (a == "--mixer-control") o.mixer_control = need(i);
        else if (a == "--mixer-device") o.mixer_device = need(i);
        else if (a == "--command-port") o.command_port = std::stoi(need(i));
        else if (a == "--acr-url") o.acr_url = need(i);
        else if (a == "--name") o.name = need(i);
        else if (a == "--sendspin-port") o.sendspin_port = static_cast<uint16_t>(std::stoi(need(i)));
        else throw std::runtime_error("unknown flag: " + a);
    }
    return o;
}
```

Uncomment the `sendspind_lib` block in `CMakeLists.txt` (restored from Task 1).

- [ ] **Step 4: Run to verify it passes**

Run: `cmake --build build --target test_options && ctest --test-dir build -R options`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: CLI options parser"
```

---

### Task 3: Volume scaling (pure)

**Files:**
- Create: `packages/sendspin/sendspin/src/volume_scale.h`, `src/volume_scale.cpp`
- Test: `packages/sendspin/sendspin/tests/test_volume_scale.cpp`

**Interfaces:**
- Produces:
  ```cpp
  long sendspin_to_raw(uint8_t v, long min, long max);   // 0..255 -> [min,max]
  uint8_t raw_to_sendspin(long raw, long min, long max);  // [min,max] -> 0..255 (rounded, clamped)
  ```

- [ ] **Step 1: Write the failing test**

```cpp
// tests/test_volume_scale.cpp
#include "volume_scale.h"
#include <cassert>

int main() {
    // full-scale endpoints
    assert(sendspin_to_raw(0, 0, 100) == 0);
    assert(sendspin_to_raw(255, 0, 100) == 100);
    // midpoint ~50
    assert(sendspin_to_raw(128, 0, 100) == 50);
    // non-zero min
    assert(sendspin_to_raw(0, -10239, 400) == -10239);
    assert(sendspin_to_raw(255, -10239, 400) == 400);
    // inverse
    assert(raw_to_sendspin(0, 0, 100) == 0);
    assert(raw_to_sendspin(100, 0, 100) == 255);
    assert(raw_to_sendspin(50, 0, 100) == 128);
    // clamp out-of-range raw
    assert(raw_to_sendspin(150, 0, 100) == 255);
    assert(raw_to_sendspin(-5, 0, 100) == 0);
    return 0;
}
```

- [ ] **Step 2: Register + run to verify it fails**

Add to `tests/CMakeLists.txt`:
```cmake
add_executable(test_volume_scale test_volume_scale.cpp)
target_link_libraries(test_volume_scale PRIVATE sendspind_lib)
add_test(NAME volume_scale COMMAND test_volume_scale)
```
Run: `cmake -S . -B build && cmake --build build --target test_volume_scale`
Expected: FAIL — `volume_scale.h` not found.

- [ ] **Step 3: Implement**

```cpp
// src/volume_scale.h
#pragma once
#include <cstdint>
long sendspin_to_raw(uint8_t v, long min, long max);
uint8_t raw_to_sendspin(long raw, long min, long max);
```

```cpp
// src/volume_scale.cpp
#include "volume_scale.h"

long sendspin_to_raw(uint8_t v, long min, long max) {
    if (max <= min) return min;
    // round to nearest
    return min + (static_cast<long>(v) * (max - min) + 127) / 255;
}

uint8_t raw_to_sendspin(long raw, long min, long max) {
    if (max <= min) return 0;
    if (raw <= min) return 0;
    if (raw >= max) return 255;
    long span = max - min;
    long v = ((raw - min) * 255 + span / 2) / span;
    if (v < 0) v = 0;
    if (v > 255) v = 255;
    return static_cast<uint8_t>(v);
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cmake --build build --target test_volume_scale && ctest --test-dir build -R volume_scale`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: sendspin<->ALSA volume scaling"
```

---

### Task 4: ACR report JSON builder (pure)

**Files:**
- Create: `packages/sendspin/sendspin/src/song.h`
- Create: `packages/sendspin/sendspin/src/report_json.h`, `src/report_json.cpp`
- Test: `packages/sendspin/sendspin/tests/test_report_json.cpp`

**Interfaces:**
- Produces:
  ```cpp
  struct Song {  // src/song.h
      std::optional<std::string> title, artist, album, artwork_url;
      std::optional<double> duration_seconds;
  };
  std::string make_state_changed(const std::string& state);   // "playing"|"paused"|"stopped"
  std::string make_song_changed(const Song& s);               // {"type":"song_changed","song":{...}}
  std::string make_position_changed(double seconds);          // {"type":"position_changed","position":N}
  ```
  `make_song_changed` emits only the present optional fields, and emits artwork under the key **`artwork_url`** (ACR 0.7.14 maps it to `cover_art_url`).

- [ ] **Step 1: Write the failing test**

```cpp
// tests/test_report_json.cpp
#include "report_json.h"
#include <nlohmann/json.hpp>
#include <cassert>
using nlohmann::json;

int main() {
    assert(json::parse(make_state_changed("playing")) ==
           json({{"type","state_changed"},{"state","playing"}}));

    Song s;
    s.title = "One"; s.artist = "Johnny Cash"; s.album = "American IV";
    s.artwork_url = "http://x/c.jpg"; s.duration_seconds = 214.0;
    json j = json::parse(make_song_changed(s));
    assert(j["type"] == "song_changed");
    assert(j["song"]["title"] == "One");
    assert(j["song"]["artist"] == "Johnny Cash");
    assert(j["song"]["album"] == "American IV");
    assert(j["song"]["artwork_url"] == "http://x/c.jpg");
    assert(j["song"]["duration"] == 214.0);

    // absent optionals are omitted
    Song empty; empty.title = "T";
    json je = json::parse(make_song_changed(empty));
    assert(je["song"].contains("title"));
    assert(!je["song"].contains("artist"));
    assert(!je["song"].contains("artwork_url"));

    json p = json::parse(make_position_changed(42.5));
    assert(p["type"] == "position_changed");
    assert(p["position"] == 42.5);
    return 0;
}
```

- [ ] **Step 2: Register + run to verify it fails**

Add to `tests/CMakeLists.txt`:
```cmake
add_executable(test_report_json test_report_json.cpp)
target_link_libraries(test_report_json PRIVATE sendspind_lib nlohmann_json::nlohmann_json)
add_test(NAME report_json COMMAND test_report_json)
```
Run: `cmake -S . -B build && cmake --build build --target test_report_json`
Expected: FAIL — `report_json.h` not found.

- [ ] **Step 3: Implement**

```cpp
// src/song.h
#pragma once
#include <optional>
#include <string>
struct Song {
    std::optional<std::string> title, artist, album, artwork_url;
    std::optional<double> duration_seconds;
};
```

```cpp
// src/report_json.h
#pragma once
#include "song.h"
#include <string>
std::string make_state_changed(const std::string& state);
std::string make_song_changed(const Song& s);
std::string make_position_changed(double seconds);
```

```cpp
// src/report_json.cpp
#include "report_json.h"
#include <nlohmann/json.hpp>
using nlohmann::json;

std::string make_state_changed(const std::string& state) {
    return json({{"type", "state_changed"}, {"state", state}}).dump();
}

std::string make_song_changed(const Song& s) {
    json song = json::object();
    if (s.title) song["title"] = *s.title;
    if (s.artist) song["artist"] = *s.artist;
    if (s.album) song["album"] = *s.album;
    if (s.duration_seconds) song["duration"] = *s.duration_seconds;
    if (s.artwork_url) song["artwork_url"] = *s.artwork_url;
    return json({{"type", "song_changed"}, {"song", song}}).dump();
}

std::string make_position_changed(double seconds) {
    return json({{"type", "position_changed"}, {"position", seconds}}).dump();
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cmake --build build --target test_report_json && ctest --test-dir build -R report_json`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: ACR report JSON builders"
```

---

### Task 5: Command parser/mapper (pure)

**Files:**
- Create: `packages/sendspin/sendspin/src/command_map.h`, `src/command_map.cpp`
- Test: `packages/sendspin/sendspin/tests/test_command_map.cpp`

**Interfaces:**
- Consumes: `sendspin::SendspinControllerCommand` from `<sendspin/controller_role.h>`.
- Produces:
  ```cpp
  struct ParsedCommand { bool valid = false; sendspin::SendspinControllerCommand cmd{}; };
  ParsedCommand parse_command(const std::string& json_body);
  ```
  Maps `play→PLAY, pause→PAUSE, stop→STOP, next→NEXT, previous→PREVIOUS`. Anything else (including `seek`) → `valid=false`. Malformed JSON → `valid=false`.

- [ ] **Step 1: Write the failing test**

```cpp
// tests/test_command_map.cpp
#include "command_map.h"
#include <cassert>
using sendspin::SendspinControllerCommand;

int main() {
    assert(parse_command(R"({"command":"play"})").valid);
    assert(parse_command(R"({"command":"play"})").cmd == SendspinControllerCommand::PLAY);
    assert(parse_command(R"({"command":"pause"})").cmd == SendspinControllerCommand::PAUSE);
    assert(parse_command(R"({"command":"stop"})").cmd == SendspinControllerCommand::STOP);
    assert(parse_command(R"({"command":"next"})").cmd == SendspinControllerCommand::NEXT);
    assert(parse_command(R"({"command":"previous"})").cmd == SendspinControllerCommand::PREVIOUS);
    // seek not supported by the Sendspin controller protocol
    assert(!parse_command(R"({"command":"seek","position":5})").valid);
    // unknown + malformed
    assert(!parse_command(R"({"command":"frobnicate"})").valid);
    assert(!parse_command("not json").valid);
    assert(!parse_command(R"({"nope":1})").valid);
    return 0;
}
```

- [ ] **Step 2: Register + run to verify it fails**

Add to `tests/CMakeLists.txt`:
```cmake
add_executable(test_command_map test_command_map.cpp)
target_link_libraries(test_command_map PRIVATE sendspind_lib)
add_test(NAME command_map COMMAND test_command_map)
```
Run: `cmake -S . -B build && cmake --build build --target test_command_map`
Expected: FAIL — `command_map.h` not found.

- [ ] **Step 3: Implement**

```cpp
// src/command_map.h
#pragma once
#include <sendspin/controller_role.h>
#include <string>
struct ParsedCommand { bool valid = false; sendspin::SendspinControllerCommand cmd{}; };
ParsedCommand parse_command(const std::string& json_body);
```

```cpp
// src/command_map.cpp
#include "command_map.h"
#include <nlohmann/json.hpp>
using sendspin::SendspinControllerCommand;

ParsedCommand parse_command(const std::string& body) {
    ParsedCommand r;
    nlohmann::json j = nlohmann::json::parse(body, nullptr, /*allow_exceptions=*/false);
    if (!j.is_object() || !j.contains("command") || !j["command"].is_string()) return r;
    std::string c = j["command"].get<std::string>();
    if (c == "play") { r.cmd = SendspinControllerCommand::PLAY; r.valid = true; }
    else if (c == "pause") { r.cmd = SendspinControllerCommand::PAUSE; r.valid = true; }
    else if (c == "stop") { r.cmd = SendspinControllerCommand::STOP; r.valid = true; }
    else if (c == "next") { r.cmd = SendspinControllerCommand::NEXT; r.valid = true; }
    else if (c == "previous") { r.cmd = SendspinControllerCommand::PREVIOUS; r.valid = true; }
    return r;
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cmake --build build --target test_command_map && ctest --test-dir build -R command_map`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: transport command parser"
```

---

### Task 6: Minimal HTTP request parser (pure)

**Files:**
- Create: `packages/sendspin/sendspin/src/http_request.h`, `src/http_request.cpp`
- Test: `packages/sendspin/sendspin/tests/test_http_request.cpp`

**Interfaces:**
- Produces:
  ```cpp
  struct HttpRequest { std::string method, path, body; bool complete = false; };
  // Parses a buffer that must contain full headers; if Content-Length is present the body
  // must be fully present for complete=true. Header names matched case-insensitively.
  HttpRequest parse_http_request(const std::string& raw);
  ```

- [ ] **Step 1: Write the failing test**

```cpp
// tests/test_http_request.cpp
#include "http_request.h"
#include <cassert>

int main() {
    std::string raw =
        "POST /command HTTP/1.1\r\nHost: x\r\nContent-Length: 18\r\n\r\n"
        "{\"command\":\"play\"}";
    HttpRequest r = parse_http_request(raw);
    assert(r.complete);
    assert(r.method == "POST");
    assert(r.path == "/command");
    assert(r.body == "{\"command\":\"play\"}");

    // headers not yet terminated -> incomplete
    assert(!parse_http_request("POST /command HTTP/1.1\r\nContent-Length: 5\r\n").complete);
    // body short of Content-Length -> incomplete
    assert(!parse_http_request(
        "POST /command HTTP/1.1\r\nContent-Length: 10\r\n\r\nshort").complete);
    // no body, no content-length -> complete with empty body
    HttpRequest g = parse_http_request("GET /x HTTP/1.1\r\n\r\n");
    assert(g.complete && g.method == "GET" && g.path == "/x" && g.body.empty());
    return 0;
}
```

- [ ] **Step 2: Register + run to verify it fails**

Add to `tests/CMakeLists.txt`:
```cmake
add_executable(test_http_request test_http_request.cpp)
target_link_libraries(test_http_request PRIVATE sendspind_lib)
add_test(NAME http_request COMMAND test_http_request)
```
Run: `cmake -S . -B build && cmake --build build --target test_http_request`
Expected: FAIL — `http_request.h` not found.

- [ ] **Step 3: Implement**

```cpp
// src/http_request.h
#pragma once
#include <string>
struct HttpRequest { std::string method, path, body; bool complete = false; };
HttpRequest parse_http_request(const std::string& raw);
```

```cpp
// src/http_request.cpp
#include "http_request.h"
#include <algorithm>
#include <cctype>
#include <sstream>

HttpRequest parse_http_request(const std::string& raw) {
    HttpRequest r;
    auto header_end = raw.find("\r\n\r\n");
    if (header_end == std::string::npos) return r;  // headers incomplete
    std::string head = raw.substr(0, header_end);
    std::string body = raw.substr(header_end + 4);

    std::istringstream hs(head);
    std::string line;
    if (!std::getline(hs, line)) return r;
    if (!line.empty() && line.back() == '\r') line.pop_back();
    std::istringstream rl(line);
    rl >> r.method >> r.path;  // "POST /command HTTP/1.1"

    long content_length = -1;
    while (std::getline(hs, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        auto colon = line.find(':');
        if (colon == std::string::npos) continue;
        std::string key = line.substr(0, colon);
        std::transform(key.begin(), key.end(), key.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        if (key == "content-length") {
            std::string val = line.substr(colon + 1);
            content_length = std::stol(val);
        }
    }

    if (content_length < 0) { r.body.clear(); r.complete = true; return r; }
    if (static_cast<long>(body.size()) < content_length) return r;  // body incomplete
    r.body = body.substr(0, static_cast<size_t>(content_length));
    r.complete = true;
    return r;
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cmake --build build --target test_http_request && ctest --test-dir build -R http_request`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: minimal HTTP request parser"
```

---

### Task 7: Metadata mapper (pure)

**Files:**
- Create: `packages/sendspin/sendspin/src/metadata_map.h`, `src/metadata_map.cpp`
- Test: `packages/sendspin/sendspin/tests/test_metadata_map.cpp`

**Interfaces:**
- Consumes: `sendspin::ServerMetadataStateObject` from `<sendspin/metadata_role.h>`; `Song` from `song.h`.
- Produces:
  ```cpp
  Song song_from_metadata(const sendspin::ServerMetadataStateObject& m);
  ```
  Copies title/artist/album/artwork_url; sets `duration_seconds` from `m.progress->track_duration / 1000.0` when progress is present and duration > 0.

- [ ] **Step 1: Write the failing test**

```cpp
// tests/test_metadata_map.cpp
#include "metadata_map.h"
#include <cassert>
using sendspin::ServerMetadataStateObject;
using sendspin::MetadataProgressObject;

int main() {
    ServerMetadataStateObject m;
    m.title = "One"; m.artist = "Johnny Cash"; m.album = "American IV";
    m.artwork_url = "http://x/c.jpg";
    m.progress = MetadataProgressObject{5000u, 214000u, 1000u};  // ms
    Song s = song_from_metadata(m);
    assert(s.title && *s.title == "One");
    assert(s.artist && *s.artist == "Johnny Cash");
    assert(s.album && *s.album == "American IV");
    assert(s.artwork_url && *s.artwork_url == "http://x/c.jpg");
    assert(s.duration_seconds && *s.duration_seconds == 214.0);

    // no progress -> no duration; missing fields stay unset
    ServerMetadataStateObject m2; m2.title = "T";
    Song s2 = song_from_metadata(m2);
    assert(s2.title && !s2.artist && !s2.duration_seconds);

    // zero duration (live stream) -> unset
    ServerMetadataStateObject m3;
    m3.progress = MetadataProgressObject{0u, 0u, 1000u};
    assert(!song_from_metadata(m3).duration_seconds);
    return 0;
}
```

- [ ] **Step 2: Register + run to verify it fails**

Add to `tests/CMakeLists.txt`:
```cmake
add_executable(test_metadata_map test_metadata_map.cpp)
target_link_libraries(test_metadata_map PRIVATE sendspind_lib)
add_test(NAME metadata_map COMMAND test_metadata_map)
```
Run: `cmake -S . -B build && cmake --build build --target test_metadata_map`
Expected: FAIL — `metadata_map.h` not found.

- [ ] **Step 3: Implement**

```cpp
// src/metadata_map.h
#pragma once
#include "song.h"
#include <sendspin/metadata_role.h>
Song song_from_metadata(const sendspin::ServerMetadataStateObject& m);
```

```cpp
// src/metadata_map.cpp
#include "metadata_map.h"

Song song_from_metadata(const sendspin::ServerMetadataStateObject& m) {
    Song s;
    if (m.title) s.title = *m.title;
    if (m.artist) s.artist = *m.artist;
    if (m.album) s.album = *m.album;
    if (m.artwork_url) s.artwork_url = *m.artwork_url;
    if (m.progress && m.progress->track_duration > 0) {
        s.duration_seconds = m.progress->track_duration / 1000.0;
    }
    return s;
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cmake --build build --target test_metadata_map && ctest --test-dir build -R metadata_map`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: sendspin metadata -> Song mapper"
```

---

### Task 8: ALSA sink (integration) + format-map unit test

**Files:**
- Create: `packages/sendspin/sendspin/src/alsa_sink.h`, `src/alsa_sink.cpp`
- Test: `packages/sendspin/sendspin/tests/test_alsa_format.cpp`

**Interfaces:**
- Produces:
  ```cpp
  snd_pcm_format_t alsa_format_for_bits(uint8_t bit_depth);  // pure, testable
  class AlsaSink {
   public:
    explicit AlsaSink(std::string device);      // e.g. "default"
    ~AlsaSink();
    bool configure(unsigned rate, unsigned channels, uint8_t bit_depth);  // main-loop thread
    size_t write(const uint8_t* data, size_t len, unsigned timeout_ms);   // audio thread
    void stop();                                 // drain+close; main-loop thread
  };
  ```
  `write` returns bytes consumed; `configure`/`write`/`stop` guard the handle with a mutex. On underrun (`-EPIPE`) it calls `snd_pcm_prepare` and retries once.

- [ ] **Step 1: Write the failing test (pure format map only)**

```cpp
// tests/test_alsa_format.cpp
#include "alsa_sink.h"
#include <cassert>

int main() {
    assert(alsa_format_for_bits(16) == SND_PCM_FORMAT_S16_LE);
    assert(alsa_format_for_bits(24) == SND_PCM_FORMAT_S24_LE);
    assert(alsa_format_for_bits(32) == SND_PCM_FORMAT_S32_LE);
    assert(alsa_format_for_bits(99) == SND_PCM_FORMAT_S16_LE);  // fallback
    return 0;
}
```

- [ ] **Step 2: Register + run to verify it fails**

Add to `tests/CMakeLists.txt`:
```cmake
add_executable(test_alsa_format test_alsa_format.cpp)
target_link_libraries(test_alsa_format PRIVATE sendspind_lib)
add_test(NAME alsa_format COMMAND test_alsa_format)
```
Run: `cmake -S . -B build && cmake --build build --target test_alsa_format`
Expected: FAIL — `alsa_sink.h` not found.

- [ ] **Step 3: Implement**

```cpp
// src/alsa_sink.h
#pragma once
#include <alsa/asoundlib.h>
#include <cstdint>
#include <mutex>
#include <string>

snd_pcm_format_t alsa_format_for_bits(uint8_t bit_depth);

class AlsaSink {
 public:
    explicit AlsaSink(std::string device);
    ~AlsaSink();
    bool configure(unsigned rate, unsigned channels, uint8_t bit_depth);
    size_t write(const uint8_t* data, size_t len, unsigned timeout_ms);
    void stop();

 private:
    std::string device_;
    snd_pcm_t* pcm_ = nullptr;
    unsigned channels_ = 2;
    unsigned frame_bytes_ = 4;  // channels * bytes_per_sample
    std::mutex mtx_;
};
```

```cpp
// src/alsa_sink.cpp
#include "alsa_sink.h"
#include <cstdio>
#include <utility>

snd_pcm_format_t alsa_format_for_bits(uint8_t bit_depth) {
    switch (bit_depth) {
        case 16: return SND_PCM_FORMAT_S16_LE;
        case 24: return SND_PCM_FORMAT_S24_LE;
        case 32: return SND_PCM_FORMAT_S32_LE;
        default: return SND_PCM_FORMAT_S16_LE;
    }
}

AlsaSink::AlsaSink(std::string device) : device_(std::move(device)) {}
AlsaSink::~AlsaSink() { stop(); }

bool AlsaSink::configure(unsigned rate, unsigned channels, uint8_t bit_depth) {
    std::lock_guard<std::mutex> lock(mtx_);
    if (pcm_) { snd_pcm_drain(pcm_); snd_pcm_close(pcm_); pcm_ = nullptr; }
    snd_pcm_format_t fmt = alsa_format_for_bits(bit_depth);
    int err = snd_pcm_open(&pcm_, device_.c_str(), SND_PCM_STREAM_PLAYBACK, 0);
    if (err < 0) {
        std::fprintf(stderr, "alsa: open %s failed: %s\n", device_.c_str(), snd_strerror(err));
        pcm_ = nullptr;
        return false;
    }
    err = snd_pcm_set_params(pcm_, fmt, SND_PCM_ACCESS_RW_INTERLEAVED,
                             channels, rate, /*soft_resample=*/1, /*latency_us=*/200000);
    if (err < 0) {
        std::fprintf(stderr, "alsa: set_params failed: %s\n", snd_strerror(err));
        snd_pcm_close(pcm_); pcm_ = nullptr;
        return false;
    }
    channels_ = channels;
    frame_bytes_ = channels * (snd_pcm_format_physical_width(fmt) / 8);
    if (frame_bytes_ == 0) frame_bytes_ = 4;
    return true;
}

size_t AlsaSink::write(const uint8_t* data, size_t len, unsigned timeout_ms) {
    std::lock_guard<std::mutex> lock(mtx_);
    if (!pcm_ || frame_bytes_ == 0) return 0;
    snd_pcm_uframes_t frames = len / frame_bytes_;
    if (frames == 0) return 0;
    if (timeout_ms > 0) snd_pcm_wait(pcm_, static_cast<int>(timeout_ms));
    snd_pcm_sframes_t written = snd_pcm_writei(pcm_, data, frames);
    if (written == -EPIPE) {            // underrun
        snd_pcm_prepare(pcm_);
        written = snd_pcm_writei(pcm_, data, frames);
    }
    if (written < 0) {
        std::fprintf(stderr, "alsa: writei failed: %s\n", snd_strerror((int)written));
        return 0;
    }
    return static_cast<size_t>(written) * frame_bytes_;
}

void AlsaSink::stop() {
    std::lock_guard<std::mutex> lock(mtx_);
    if (pcm_) { snd_pcm_drain(pcm_); snd_pcm_close(pcm_); pcm_ = nullptr; }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cmake --build build --target test_alsa_format && ctest --test-dir build -R alsa_format`
Expected: PASS. (Full playback is verified on-device in Task 15's smoke test.)

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: ALSA default-device sink"
```

---

### Task 9: Volume control (integration)

**Files:**
- Create: `packages/sendspin/sendspin/src/volume_control.h`, `src/volume_control.cpp`

**Interfaces:**
- Consumes: `sendspin_to_raw` / `raw_to_sendspin` from `volume_scale.h`.
- Produces:
  ```cpp
  class VolumeControl {
   public:
    VolumeControl(std::string mixer_device, std::string control_name);  // e.g. "hw:0","Digital"
    ~VolumeControl();
    bool open();                       // false if control missing/empty
    void set_sendspin_volume(uint8_t v);   // apply MA volume to the mixer
    void set_muted(bool muted);
    // Returns the current mixer value as a sendspin 0-255 volume, or -1 if unavailable.
    int current_sendspin_volume();
  };
  ```
  No unit test (requires a real mixer); exercised in the Task 15 on-device smoke test. Keep it thin — all math lives in the already-tested `volume_scale`.

- [ ] **Step 1: Implement the header**

```cpp
// src/volume_control.h
#pragma once
#include <alsa/asoundlib.h>
#include <cstdint>
#include <mutex>
#include <string>

class VolumeControl {
 public:
    VolumeControl(std::string mixer_device, std::string control_name);
    ~VolumeControl();
    bool open();
    void set_sendspin_volume(uint8_t v);
    void set_muted(bool muted);
    int current_sendspin_volume();

 private:
    std::string device_, control_;
    snd_mixer_t* handle_ = nullptr;
    snd_mixer_elem_t* elem_ = nullptr;
    long min_ = 0, max_ = 0;
    std::mutex mtx_;
};
```

- [ ] **Step 2: Implement the source**

```cpp
// src/volume_control.cpp
#include "volume_control.h"
#include "volume_scale.h"
#include <cstdio>
#include <utility>

VolumeControl::VolumeControl(std::string device, std::string control)
    : device_(std::move(device)), control_(std::move(control)) {}

VolumeControl::~VolumeControl() {
    std::lock_guard<std::mutex> lock(mtx_);
    if (handle_) snd_mixer_close(handle_);
}

bool VolumeControl::open() {
    std::lock_guard<std::mutex> lock(mtx_);
    if (control_.empty()) {
        std::fprintf(stderr, "volume: no mixer control name; volume disabled\n");
        return false;
    }
    if (snd_mixer_open(&handle_, 0) < 0) return false;
    if (snd_mixer_attach(handle_, device_.c_str()) < 0) return false;
    if (snd_mixer_selem_register(handle_, nullptr, nullptr) < 0) return false;
    if (snd_mixer_load(handle_) < 0) return false;

    snd_mixer_selem_id_t* sid;
    snd_mixer_selem_id_alloca(&sid);
    snd_mixer_selem_id_set_index(sid, 0);
    snd_mixer_selem_id_set_name(sid, control_.c_str());
    elem_ = snd_mixer_find_selem(handle_, sid);
    if (!elem_) {
        std::fprintf(stderr, "volume: control '%s' not found on %s\n",
                     control_.c_str(), device_.c_str());
        return false;
    }
    snd_mixer_selem_get_playback_volume_range(elem_, &min_, &max_);
    return true;
}

void VolumeControl::set_sendspin_volume(uint8_t v) {
    std::lock_guard<std::mutex> lock(mtx_);
    if (!elem_) return;
    long raw = sendspin_to_raw(v, min_, max_);
    snd_mixer_selem_set_playback_volume_all(elem_, raw);
}

void VolumeControl::set_muted(bool muted) {
    std::lock_guard<std::mutex> lock(mtx_);
    if (!elem_) return;
    if (snd_mixer_selem_has_playback_switch(elem_)) {
        snd_mixer_selem_set_playback_switch_all(elem_, muted ? 0 : 1);
    }
}

int VolumeControl::current_sendspin_volume() {
    std::lock_guard<std::mutex> lock(mtx_);
    if (!elem_) return -1;
    snd_mixer_handle_events(handle_);
    long raw = 0;
    if (snd_mixer_selem_get_playback_volume(elem_, SND_MIXER_SCHN_FRONT_LEFT, &raw) < 0) return -1;
    return raw_to_sendspin(raw, min_, max_);
}
```

- [ ] **Step 3: Build to verify it compiles**

Run: `cmake --build build --target sendspind_lib`
Expected: compiles clean.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: ALSA mixer volume control"
```

---

### Task 10: ACR reporter (integration)

**Files:**
- Create: `packages/sendspin/sendspin/src/acr_reporter.h`, `src/acr_reporter.cpp`

**Interfaces:**
- Consumes: nothing from other tasks except being handed already-built JSON strings.
- Produces:
  ```cpp
  class AcrReporter {
   public:
    explicit AcrReporter(std::string url);
    ~AcrReporter();                     // stops the worker
    void start();                       // spawn background POST thread
    void post(std::string json_body);   // enqueue; never blocks the caller
  };
  ```
  A single worker thread drains a queue and POSTs each body with libcurl (`Content-Type: application/json`, 2 s timeout). A failed POST is logged and dropped — audio never blocks.

- [ ] **Step 1: Implement the header**

```cpp
// src/acr_reporter.h
#pragma once
#include <condition_variable>
#include <deque>
#include <mutex>
#include <string>
#include <thread>

class AcrReporter {
 public:
    explicit AcrReporter(std::string url);
    ~AcrReporter();
    void start();
    void post(std::string json_body);

 private:
    void run();
    std::string url_;
    std::thread worker_;
    std::deque<std::string> queue_;
    std::mutex mtx_;
    std::condition_variable cv_;
    bool stop_ = false;
};
```

- [ ] **Step 2: Implement the source**

```cpp
// src/acr_reporter.cpp
#include "acr_reporter.h"
#include <curl/curl.h>
#include <cstdio>
#include <utility>

static size_t discard_body(char*, size_t size, size_t nmemb, void*) { return size * nmemb; }

AcrReporter::AcrReporter(std::string url) : url_(std::move(url)) {
    curl_global_init(CURL_GLOBAL_DEFAULT);
}

AcrReporter::~AcrReporter() {
    {
        std::lock_guard<std::mutex> lock(mtx_);
        stop_ = true;
    }
    cv_.notify_all();
    if (worker_.joinable()) worker_.join();
    curl_global_cleanup();
}

void AcrReporter::start() { worker_ = std::thread(&AcrReporter::run, this); }

void AcrReporter::post(std::string json_body) {
    {
        std::lock_guard<std::mutex> lock(mtx_);
        if (stop_) return;
        queue_.push_back(std::move(json_body));
    }
    cv_.notify_one();
}

void AcrReporter::run() {
    CURL* curl = curl_easy_init();
    struct curl_slist* headers = curl_slist_append(nullptr, "Content-Type: application/json");
    while (true) {
        std::string body;
        {
            std::unique_lock<std::mutex> lock(mtx_);
            cv_.wait(lock, [&] { return stop_ || !queue_.empty(); });
            if (stop_ && queue_.empty()) break;
            body = std::move(queue_.front());
            queue_.pop_front();
        }
        if (!curl) continue;
        curl_easy_setopt(curl, CURLOPT_URL, url_.c_str());
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body.c_str());
        curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, (long)body.size());
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
        curl_easy_setopt(curl, CURLOPT_TIMEOUT, 2L);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, discard_body);
        CURLcode rc = curl_easy_perform(curl);
        if (rc != CURLE_OK)
            std::fprintf(stderr, "acr: POST failed: %s\n", curl_easy_strerror(rc));
    }
    curl_slist_free_all(headers);
    if (curl) curl_easy_cleanup(curl);
}
```

- [ ] **Step 3: Build to verify it compiles**

Run: `cmake --build build --target sendspind_lib`
Expected: compiles clean.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: async ACR reporter (libcurl)"
```

---

### Task 11: Command HTTP server (integration)

**Files:**
- Create: `packages/sendspin/sendspin/src/command_server.h`, `src/command_server.cpp`

**Interfaces:**
- Consumes: `parse_http_request` (`http_request.h`), `parse_command` (`command_map.h`).
- Produces:
  ```cpp
  class CommandServer {
   public:
    using Handler = std::function<void(const ParsedCommand&)>;
    CommandServer(int port, Handler handler);   // binds 127.0.0.1:port
    ~CommandServer();                           // stops the accept thread
    bool start();                               // returns false if bind fails
  };
  ```
  Accept loop on a background thread. For each connection: read until `parse_http_request(...).complete`, run the handler if the parsed command is valid, respond `200 OK` (or `400` for an invalid command body), close. Localhost only; `Content-Length` required (matches ureq).

- [ ] **Step 1: Implement the header**

```cpp
// src/command_server.h
#pragma once
#include "command_map.h"
#include <atomic>
#include <functional>
#include <thread>

class CommandServer {
 public:
    using Handler = std::function<void(const ParsedCommand&)>;
    CommandServer(int port, Handler handler);
    ~CommandServer();
    bool start();

 private:
    void run();
    int port_;
    Handler handler_;
    int listen_fd_ = -1;
    std::thread thread_;
    std::atomic<bool> stop_{false};
};
```

- [ ] **Step 2: Implement the source**

```cpp
// src/command_server.cpp
#include "command_server.h"
#include "http_request.h"
#include <arpa/inet.h>
#include <cstdio>
#include <cstring>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
#include <utility>

CommandServer::CommandServer(int port, Handler handler)
    : port_(port), handler_(std::move(handler)) {}

CommandServer::~CommandServer() {
    stop_ = true;
    if (listen_fd_ >= 0) { ::shutdown(listen_fd_, SHUT_RDWR); ::close(listen_fd_); }
    if (thread_.joinable()) thread_.join();
}

bool CommandServer::start() {
    listen_fd_ = ::socket(AF_INET, SOCK_STREAM, 0);
    if (listen_fd_ < 0) return false;
    int one = 1;
    ::setsockopt(listen_fd_, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));
    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(static_cast<uint16_t>(port_));
    ::inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr);
    if (::bind(listen_fd_, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) < 0) {
        std::fprintf(stderr, "command: bind 127.0.0.1:%d failed\n", port_);
        ::close(listen_fd_); listen_fd_ = -1;
        return false;
    }
    if (::listen(listen_fd_, 4) < 0) { ::close(listen_fd_); listen_fd_ = -1; return false; }
    thread_ = std::thread(&CommandServer::run, this);
    return true;
}

void CommandServer::run() {
    while (!stop_) {
        int fd = ::accept(listen_fd_, nullptr, nullptr);
        if (fd < 0) { if (stop_) break; continue; }
        std::string raw;
        char buf[2048];
        HttpRequest req;
        for (int i = 0; i < 16; ++i) {  // bounded reads
            ssize_t n = ::recv(fd, buf, sizeof(buf), 0);
            if (n <= 0) break;
            raw.append(buf, static_cast<size_t>(n));
            req = parse_http_request(raw);
            if (req.complete) break;
        }
        const char* resp = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n";
        if (req.complete && req.path == "/command") {
            ParsedCommand pc = parse_command(req.body);
            if (pc.valid) { if (handler_) handler_(pc); }
            else resp = "HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\n\r\n";
        } else {
            resp = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n";
        }
        ::send(fd, resp, std::strlen(resp), 0);
        ::close(fd);
    }
}
```

- [ ] **Step 3: Build to verify it compiles**

Run: `cmake --build build --target sendspind_lib`
Expected: compiles clean.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: HTTP command server (127.0.0.1:3547)"
```

---

### Task 12: mDNS advertiser (integration)

**Files:**
- Create: `packages/sendspin/sendspin/src/mdns.h`, `src/mdns.cpp`

**Interfaces:**
- Produces:
  ```cpp
  class MdnsAdvertiser {
   public:
    ~MdnsAdvertiser();
    bool start(const std::string& name, uint16_t port, const std::string& path);  // "/sendspin"
    void stop();
  };
  ```
  Uses `DNSServiceRegister` for `_sendspin._tcp` with TXT keys `path` + `name` (ported from the sendspin-cpp `basic_client` example).

- [ ] **Step 1: Implement the header**

```cpp
// src/mdns.h
#pragma once
#include <dns_sd.h>
#include <cstdint>
#include <string>

class MdnsAdvertiser {
 public:
    ~MdnsAdvertiser();
    bool start(const std::string& name, uint16_t port, const std::string& path);
    void stop();

 private:
    DNSServiceRef service_ref_ = nullptr;
};
```

- [ ] **Step 2: Implement the source**

```cpp
// src/mdns.cpp
#include "mdns.h"
#include <arpa/inet.h>
#include <cstdio>

MdnsAdvertiser::~MdnsAdvertiser() { stop(); }

bool MdnsAdvertiser::start(const std::string& name, uint16_t port, const std::string& path) {
    TXTRecordRef txt;
    TXTRecordCreate(&txt, 0, nullptr);
    TXTRecordSetValue(&txt, "path", static_cast<uint8_t>(path.size()), path.c_str());
    TXTRecordSetValue(&txt, "name", static_cast<uint8_t>(name.size()), name.c_str());

    DNSServiceErrorType err = DNSServiceRegister(
        &service_ref_, 0, 0, name.c_str(), "_sendspin._tcp", nullptr, nullptr,
        htons(port), TXTRecordGetLength(&txt), TXTRecordGetBytesPtr(&txt), nullptr, nullptr);

    TXTRecordDeallocate(&txt);
    if (err != kDNSServiceErr_NoError) {
        std::fprintf(stderr, "mdns: register failed: %d\n", err);
        return false;
    }
    std::fprintf(stderr, "mdns: advertising _sendspin._tcp:%u (%s)\n", port, name.c_str());
    return true;
}

void MdnsAdvertiser::stop() {
    if (service_ref_) { DNSServiceRefDeallocate(service_ref_); service_ref_ = nullptr; }
}
```

- [ ] **Step 3: Build to verify it compiles**

Run: `cmake --build build --target sendspind_lib`
Expected: compiles clean.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: mDNS _sendspin._tcp advertiser"
```

---

### Task 13: Listeners + main wiring (integration)

**Files:**
- Create: `packages/sendspin/sendspin/src/listeners.h`, `src/listeners.cpp`
- Modify: `packages/sendspin/sendspin/src/main.cpp` (replace the Task-1 stub)

**Interfaces:**
- Consumes: everything above — `Options`, `AlsaSink`, `VolumeControl`, `AcrReporter`, `CommandServer`, `MdnsAdvertiser`, `report_json`, `metadata_map`, and the sendspin-cpp roles/listeners.
- Produces: the wired `sendspind` binary.

Design notes for the implementer:
- `PlayerListener::on_audio_write` (audio thread) → `sink.write(...)`. `on_stream_start` (main thread) → read `player_->get_current_stream_params()` and `sink.configure(rate, channels, bit_depth)`, then POST `state_changed:"playing"`. `on_stream_end` → `sink.stop()`, POST `state_changed:"stopped"`. `on_volume_changed(v)` → `volume.set_sendspin_volume(v)` and record `last_applied_volume_=v`. `on_mute_changed(m)` → `volume.set_muted(m)`.
- `MetadataListener::on_metadata(m)` → `reporter.post(make_song_changed(song_from_metadata(m)))`. `on_metadata_clear` → POST `state_changed:"stopped"`.
- Command handler (from `CommandServer`, runs on its thread) → `controller_->send_command(pc.cmd)`. `ControllerRole::send_command` publishes to the active connection; it is safe to call from another thread only if the library requires main-thread calls — to stay safe, push the command into a `std::mutex`-guarded pending queue and dispatch it from the main loop. Implement a tiny thread-safe `PendingCommands` holder in `listeners.h`.
- Volume monitor: in the main loop, every ~1 s call `volume.current_sendspin_volume()`; if it differs from `last_applied_volume_`, call `player_->update_volume(v)` and set `last_applied_volume_=v` (set-if-changed guard; avoids the MA→mixer→MA loop).
- Position: in the main loop, every ~1 s, if connected and a duration is known, POST `make_position_changed(metadata_->get_track_progress_ms()/1000.0)`.
- `NetworkProvider::is_network_ready()` → `return true;` (host always ready).

- [ ] **Step 1: Implement `listeners.h`**

```cpp
// src/listeners.h
#pragma once
#include "acr_reporter.h"
#include "alsa_sink.h"
#include "command_map.h"
#include "volume_control.h"
#include <atomic>
#include <deque>
#include <mutex>
#include <sendspin/client.h>
#include <sendspin/metadata_role.h>
#include <sendspin/player_role.h>

// Thread-safe holder for controller commands produced off the main loop.
class PendingCommands {
 public:
    void push(sendspin::SendspinControllerCommand c) {
        std::lock_guard<std::mutex> lock(mtx_); q_.push_back(c);
    }
    bool pop(sendspin::SendspinControllerCommand& out) {
        std::lock_guard<std::mutex> lock(mtx_);
        if (q_.empty()) return false;
        out = q_.front(); q_.pop_front(); return true;
    }
 private:
    std::deque<sendspin::SendspinControllerCommand> q_;
    std::mutex mtx_;
};

class PlayerListener : public sendspin::PlayerRoleListener {
 public:
    PlayerListener(AlsaSink& sink, VolumeControl& vol, AcrReporter& reporter,
                   sendspin::PlayerRole** player, std::atomic<int>* last_applied)
        : sink_(sink), vol_(vol), reporter_(reporter), player_(player),
          last_applied_(last_applied) {}
    size_t on_audio_write(uint8_t* data, size_t len, uint32_t timeout_ms) override {
        return sink_.write(data, len, timeout_ms);
    }
    void on_stream_start() override;
    void on_stream_end() override;
    void on_volume_changed(uint8_t v) override;
    void on_mute_changed(bool muted) override;

 private:
    AlsaSink& sink_;
    VolumeControl& vol_;
    AcrReporter& reporter_;
    sendspin::PlayerRole** player_;
    std::atomic<int>* last_applied_;
};

class MetaListener : public sendspin::MetadataRoleListener {
 public:
    explicit MetaListener(AcrReporter& reporter) : reporter_(reporter) {}
    void on_metadata(const sendspin::ServerMetadataStateObject& m) override;
    void on_metadata_clear() override;
 private:
    AcrReporter& reporter_;
};

class NetProvider : public sendspin::SendspinNetworkProvider {
 public:
    bool is_network_ready() override { return true; }
};
```

- [ ] **Step 2: Implement `listeners.cpp`**

```cpp
// src/listeners.cpp
#include "listeners.h"
#include "metadata_map.h"
#include "report_json.h"

void PlayerListener::on_stream_start() {
    if (*player_) {
        const auto& p = (*player_)->get_current_stream_params();
        unsigned rate = p.sample_rate.value_or(44100);
        unsigned ch = p.channels.value_or(2);
        uint8_t bits = p.bit_depth.value_or(16);
        sink_.configure(rate, ch, bits);
    }
    reporter_.post(make_state_changed("playing"));
}

void PlayerListener::on_stream_end() {
    sink_.stop();
    reporter_.post(make_state_changed("stopped"));
}

void PlayerListener::on_volume_changed(uint8_t v) {
    vol_.set_sendspin_volume(v);
    last_applied_->store(v);
}

void PlayerListener::on_mute_changed(bool muted) { vol_.set_muted(muted); }

void MetaListener::on_metadata(const sendspin::ServerMetadataStateObject& m) {
    reporter_.post(make_song_changed(song_from_metadata(m)));
}

void MetaListener::on_metadata_clear() { reporter_.post(make_state_changed("stopped")); }
```

- [ ] **Step 3: Implement `main.cpp`**

```cpp
// src/main.cpp
#include "acr_reporter.h"
#include "alsa_sink.h"
#include "command_server.h"
#include "listeners.h"
#include "mdns.h"
#include "options.h"
#include "report_json.h"
#include "volume_control.h"
#include <atomic>
#include <chrono>
#include <csignal>
#include <cstdio>
#include <cstring>
#include <sendspin/client.h>
#include <sendspin/controller_role.h>
#include <sendspin/metadata_role.h>
#include <sendspin/player_role.h>
#include <thread>

static std::atomic<bool> g_running{true};
static void on_sigterm(int) { g_running = false; }

int main(int argc, char** argv) {
    for (int i = 1; i < argc; ++i)
        if (std::strcmp(argv[i], "--version") == 0) { std::printf("sendspind 0.1.0\n"); return 0; }

    Options opt;
    try { opt = parse_args(argc, argv); }
    catch (const std::exception& e) { std::fprintf(stderr, "args: %s\n", e.what()); return 2; }

    std::signal(SIGINT, on_sigterm);
    std::signal(SIGTERM, on_sigterm);

    AlsaSink sink(opt.alsa_device);
    VolumeControl volume(opt.mixer_device, opt.mixer_control);
    volume.open();  // volume disabled gracefully if control missing
    AcrReporter reporter(opt.acr_url);
    reporter.start();

    // sendspin client
    using namespace sendspin;
    SendspinClientConfig cfg;
    cfg.client_id = opt.name;   // stable-ish id; MA also gets a MAC via auto-detect
    cfg.name = opt.name;
    cfg.product_name = "HiFiBerry";
    cfg.manufacturer = "HiFiBerry";
    cfg.software_version = "0.1.0";
    cfg.server_port = opt.sendspin_port;
    SendspinClient client(std::move(cfg));

    PlayerRole* player_ptr = nullptr;
    std::atomic<int> last_applied{-1};

    PlayerRoleConfig pcfg;
    pcfg.audio_formats = {
        {SendspinCodecFormat::FLAC, 2, 44100, 16},
        {SendspinCodecFormat::OPUS, 2, 48000, 16},
        {SendspinCodecFormat::PCM,  2, 44100, 16},
    };
    auto& player = client.add_player(std::move(pcfg));
    player_ptr = &player;
    auto& controller = client.add_controller();
    auto& metadata = client.add_metadata();

    PlayerListener player_listener(sink, volume, reporter, &player_ptr, &last_applied);
    MetaListener meta_listener(reporter);
    NetProvider net;
    player.set_listener(&player_listener);
    metadata.set_listener(&meta_listener);
    client.set_network_provider(&net);

    PendingCommands pending;
    CommandServer cmd_server(opt.command_port, [&pending](const ParsedCommand& pc) {
        pending.push(pc.cmd);   // dispatched on the main loop below
    });
    if (!cmd_server.start())
        std::fprintf(stderr, "warning: command server failed to bind :%d\n", opt.command_port);

    if (!client.start_server()) { std::fprintf(stderr, "sendspin: start_server failed\n"); return 1; }

    MdnsAdvertiser mdns;
    mdns.start(opt.name, opt.sendspin_port, "/sendspin");

    auto last_poll = std::chrono::steady_clock::now();
    while (g_running.load()) {
        client.loop();

        // dispatch queued transport commands on the main loop thread
        SendspinControllerCommand c;
        while (pending.pop(c)) controller.send_command(c);

        auto now = std::chrono::steady_clock::now();
        if (now - last_poll >= std::chrono::seconds(1)) {
            last_poll = now;
            // local volume change -> report to MA (set-if-changed)
            int cur = volume.current_sendspin_volume();
            if (cur >= 0 && cur != last_applied.load()) {
                player.update_volume(static_cast<uint8_t>(cur));
                last_applied.store(cur);
            }
            // position -> ACR
            if (client.is_connected()) {
                uint32_t dur = metadata.get_track_duration_ms();
                if (dur > 0)
                    reporter.post(make_position_changed(metadata.get_track_progress_ms() / 1000.0));
            }
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    return 0;
}
```

- [ ] **Step 4: Build the full binary**

Run: `cmake -S . -B build && cmake --build build -j4`
Expected: `sendspind` links; all unit tests still build.

- [ ] **Step 5: Run the unit suite**

Run: `ctest --test-dir build --output-on-failure`
Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: wire listeners, roles, and main loop"
```

---

### Task 14: systemd start wrapper

**Files:**
- Create: `packages/sendspin/sendspin/scripts/start-sendspin.sh`

**Interfaces:**
- Produces: `/usr/bin/start-sendspin` — discovers device/mixer/name and execs `sendspind`.

- [ ] **Step 1: Write the wrapper**

```sh
#!/bin/bash
# start-sendspin.sh — discovers the sound card volume control and pretty hostname,
# then launches sendspind. Runs from the sendspin systemd *user* service.
set -u

# Only run as root or the configured HiFiBerry user (mirrors start-shairport.sh)
CURRENT_USER=$(whoami)
if [ "$CURRENT_USER" != "root" ] && [ -f /etc/hifiberry.user ]; then
  AUTH_USER=$(tr -d '\n\r ' < /etc/hifiberry.user)
  if [ "$CURRENT_USER" != "$AUTH_USER" ]; then
    echo "Not starting sendspin: must run as $AUTH_USER"; exit 0
  fi
fi

# Sound card guard
if ! /usr/bin/config-soundcard --detect >/dev/null 2>&1; then
  echo "No sound card detected, not starting sendspin"; exit 0
fi

NAME=$(hostnamectl hostname --pretty 2>/dev/null)
[ -n "$NAME" ] || NAME=$(hostname 2>/dev/null)
[ -n "$NAME" ] || NAME="HiFiBerry"

MIXER=$(config-soundcard --no-eeprom --volume-control-softvol 2>/dev/null)
HWIDX=$(config-soundcard --no-eeprom --hw 2>/dev/null)
[ -n "$HWIDX" ] || HWIDX=0

exec /usr/bin/sendspind \
  --alsa-device default \
  --mixer-control "$MIXER" \
  --mixer-device "hw:$HWIDX" \
  --command-port 3547 \
  --acr-url http://localhost:1080/api/player/sendspin/update \
  --name "$NAME"
```

- [ ] **Step 2: Verify it is valid shell**

Run: `bash -n packages/sendspin/sendspin/scripts/start-sendspin.sh && chmod +x packages/sendspin/sendspin/scripts/start-sendspin.sh`
Expected: no syntax errors.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: start-sendspin systemd wrapper"
```

---

### Task 15: Debian packaging + registration files + on-device smoke test

**Files (all under `packages/sendspin/sendspin/`):**
- Create: `debian/changelog`, `debian/control`, `debian/compat`, `debian/rules`, `debian/copyright`
- Create: `debian/sendspin.install`, `debian/sendspin.dirs`, `debian/sendspin.postinst`, `debian/sendspin.postrm`
- Create: `data/usr/lib/systemd/user/sendspin.service`
- Create: `data/etc/hifiberry/players.d/sendspin.json`
- Create: `data/etc/hifiberry/players.d/icons/sendspin.svg`
- Create: `data/etc/configserver/conf.d/sendspin.json`
- Create: `data/etc/audiocontrol/players.d/sendspin.json`

**Interfaces:**
- Produces: `hifiberry-sendspin_0.1.0_arm64.deb` installing `sendspind`, `start-sendspin`, the user service, and the three registration JSONs + icon.

- [ ] **Step 1: Write the three registration JSONs + icon + service**

`data/etc/hifiberry/players.d/sendspin.json`:
```json
{
    "name": "Music Assistant",
    "provided_by": "sendspin",
    "systemd_service": "sendspin",
    "icon": "sendspin",
    "allow_change": true
}
```
`data/etc/configserver/conf.d/sendspin.json`:
```json
{ "systemd": { "sendspin": "all" } }
```
`data/etc/audiocontrol/players.d/sendspin.json`:
```json
{
    "generic": {
        "name": "sendspin",
        "enable": true,
        "supports_api_events": true,
        "capabilities": ["play", "pause", "stop", "next", "previous", "killable"],
        "command_url": "http://127.0.0.1:3547/command"
    }
}
```
`data/etc/hifiberry/players.d/icons/sendspin.svg` — a simple placeholder speaker/stream glyph (24×24 viewBox, single `<path>`); reuse the visual style of shairport's `airplay.svg`.

`data/usr/lib/systemd/user/sendspin.service` (**user** service — matches shairport):
```ini
[Unit]
Description=Sendspin Player (Music Assistant)
After=sound.target network.target pipewire.service
Wants=avahi-daemon.service

[Service]
Type=simple
ExecStart=/usr/bin/start-sendspin
Restart=on-failure
RestartSec=2

[Install]
WantedBy=default.target
```

- [ ] **Step 2: Write the debian metadata**

`debian/compat`:
```
13
```
`debian/control`:
```
Source: hifiberry-sendspin
Section: sound
Priority: optional
Maintainer: HiFiBerry <support@hifiberry.com>
Build-Depends: debhelper-compat (= 13), cmake, build-essential,
 libasound2-dev, libcurl4-openssl-dev, nlohmann-json3-dev,
 libavahi-compat-libdnssd-dev, git, ca-certificates
Standards-Version: 4.6.0
Homepage: https://github.com/hifiberry/sendspin

Package: hifiberry-sendspin
Architecture: any
Depends: ${shlibs:Depends}, ${misc:Depends},
 libasound2, libcurl4, libavahi-compat-libdnssd1, hifiberry-configurator
Description: Sendspin player for HiFiBerryOS
 Renders Music Assistant's native Sendspin stream to the HiFiBerry sound card,
 reports metadata to audiocontrol, and forwards transport commands to Music
 Assistant.
```
`debian/changelog`:
```
hifiberry-sendspin (0.1.0) trixie; urgency=medium

  * Initial release: Sendspin player daemon (player/controller/metadata roles),
    ALSA default-device output, ALSA mixer volume, audiocontrol metadata push,
    transport command endpoint, mDNS advertisement.

 -- HiFiBerry <support@hifiberry.com>  Wed, 08 Jul 2026 12:00:00 +0000
```
`debian/copyright` — standard HiFiBerry MIT header (copy the form used in `packages/shairport-sync/src/debian/copyright`).

- [ ] **Step 3: Write `debian/rules`**

```makefile
#!/usr/bin/make -f
export DEB_BUILD_MAINT_OPTIONS = hardening=+all

%:
	dh $@

override_dh_auto_configure:
	cmake -S . -B build -DCMAKE_BUILD_TYPE=Release

override_dh_auto_build:
	cmake --build build -j$(shell nproc)

override_dh_auto_test:
	ctest --test-dir build --output-on-failure

override_dh_auto_install:
	install -D -m0755 build/sendspind debian/hifiberry-sendspin/usr/bin/sendspind
	install -D -m0755 scripts/start-sendspin.sh debian/hifiberry-sendspin/usr/bin/start-sendspin
	cp -r data/* debian/hifiberry-sendspin/
```

Make executable: `chmod +x debian/rules`.

- [ ] **Step 4: Write `debian/sendspin.dirs`, `.install` (empty — install handled in rules), postinst/postrm**

`debian/sendspin.dirs`:
```
usr/bin
```
`debian/sendspin.postinst`:
```sh
#!/bin/sh
set -e
# Reload user service manager registration is handled per-user by the WebUI;
# nothing to enable here — the player is toggled on via the HiFiBerry UI.
#DEBHELPER#
exit 0
```
`debian/sendspin.postrm`:
```sh
#!/bin/sh
set -e
#DEBHELPER#
exit 0
```
(Leave `debian/sendspin.install` unused; installation is done in `rules`. Do not create it.)

- [ ] **Step 5: Build the deb on the build host**

Run (build host, in the repo checkout):
```bash
dpkg-buildpackage -us -uc -b 2>&1 | tail -20
ls -la ../hifiberry-sendspin_0.1.0_*.deb
```
Expected: a `.deb` is produced; `ctest` ran green during the build.

- [ ] **Step 6: On-device smoke test (tannoy 192.168.1.12)**

Install and verify end-to-end:
```bash
# copy + install
scp ../hifiberry-sendspin_0.1.0_*.deb matuschd@192.168.1.12:/tmp/
ssh matuschd@192.168.1.12 'sudo apt-get install -y /tmp/hifiberry-sendspin_0.1.0_*.deb'
# enable + start the user service under the hifiberry user
ssh matuschd@192.168.1.12 'HB=$(cat /etc/hifiberry.user); \
  sudo systemctl --machine="$HB"@ --user enable --now sendspin.service; \
  sudo systemctl --machine="$HB"@ --user status sendspin.service --no-pager | head -20'
# confirm mDNS advert + ACR sees the player
ssh matuschd@192.168.1.12 'avahi-browse -rt _sendspin._tcp | head; \
  curl -s http://localhost:1080/api/players | grep -i sendspin'
```
Expected: service active; `_sendspin._tcp` advertised; `sendspin` present in ACR's player list. Then, from Music Assistant, add the device as a Sendspin player, start playback, and confirm: audio plays, HiFiBerry now-playing shows title/artist/cover art, transport buttons control MA, and volume tracks both directions. Record the results in the task report.

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat: Debian packaging + registration + systemd user service"
```

---

### Task 16: Repo build.sh (own build script)

**Files:**
- Create: `packages/sendspin/sendspin/build.sh`

**Interfaces:**
- Produces: `build.sh` that builds the `.deb` via `dpkg-buildpackage` (invoked by the hifiberry-os wrapper in Task 18).

- [ ] **Step 1: Write `build.sh`**

```bash
#!/bin/bash
set -e
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR"
echo "Building hifiberry-sendspin..."
dpkg-buildpackage -us -uc -b
echo "Built packages:"
ls -lh ../hifiberry-sendspin_*.deb
```

- [ ] **Step 2: Verify shell validity**

Run: `bash -n packages/sendspin/sendspin/build.sh && chmod +x packages/sendspin/sendspin/build.sh`
Expected: no syntax errors.

- [ ] **Step 3: Commit + push the new repo to GitHub**

```bash
git add -A && git commit -m "build: repo build.sh"
# create github.com/hifiberry/sendspin (gh CLI) and push
gh repo create hifiberry/sendspin --public --source=. --remote=origin --push 2>/dev/null \
  || (git remote add origin https://github.com/hifiberry/sendspin.git && git push -u origin HEAD)
```
Expected: repo exists at `github.com/hifiberry/sendspin` with all commits.

---

### Task 17: ACR generic-player `command_url` (Component B)

**Files:**
- Modify: `packages/acr/acr/src/players/generic/generic_controller.rs` (the `send_command` impl at ~line 441, plus config parsing where the struct is built)
- Modify: `packages/acr/acr/src/players/generic/tests.rs`
- Modify: `packages/acr/acr/Cargo.toml` (version → 0.7.15)
- Modify: `packages/acr/acr/debian/changelog` (add 0.7.15 entry)

**Interfaces:**
- Consumes: the existing `GenericPlayerController` and its `from_config`.
- Produces: when `command_url` is set in config, `send_command` POSTs `{"command":"<verb>"}` to it via `ureq`; when unset, behaviour is unchanged.

This is a Rust repo (`packages/acr/acr`, its own git checkout on branch `main`). Read the top of `generic_controller.rs` to find the struct fields and `from_config` before editing.

- [ ] **Step 1: Write the failing test**

Add to `packages/acr/acr/src/players/generic/tests.rs` inside the `mod tests` block:
```rust
    #[test]
    fn test_command_url_posts_on_send_command() {
        use std::io::{Read, Write};
        use std::net::TcpListener;
        use std::sync::mpsc;
        use std::thread;

        // Minimal one-shot HTTP server capturing the POST body.
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let addr = listener.local_addr().unwrap();
        let (tx, rx) = mpsc::channel();
        thread::spawn(move || {
            if let Ok((mut stream, _)) = listener.accept() {
                let mut buf = [0u8; 1024];
                let n = stream.read(&mut buf).unwrap();
                let req = String::from_utf8_lossy(&buf[..n]).to_string();
                let _ = stream.write_all(b"HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n");
                let _ = tx.send(req);
            }
        });

        let config = json!({
            "name": "sendspin",
            "supports_api_events": true,
            "command_url": format!("http://{}/command", addr)
        });
        let controller = GenericPlayerController::from_config(&config).unwrap();
        assert!(controller.send_command(PlayerCommand::Pause));

        let req = rx.recv_timeout(std::time::Duration::from_secs(2)).expect("no POST received");
        assert!(req.contains("POST /command"));
        assert!(req.contains("\"command\":\"pause\""));
    }
```

- [ ] **Step 2: Run to verify it fails**

Run (on the build host, in `packages/acr/acr`):
```bash
cargo test --lib players::generic::tests::tests::test_command_url_posts_on_send_command
```
Expected: FAIL — `command_url` is not read; no POST is sent.

- [ ] **Step 3: Add the `command_url` field + parsing**

In `generic_controller.rs`, add a field to the controller struct:
```rust
    /// Optional URL to POST transport commands to (external player bridge).
    command_url: Option<String>,
```
Initialize it in `new()` to `None`, and in `from_config` read it:
```rust
        let command_url = config
            .get("command_url")
            .and_then(|v| v.as_str())
            .map(|s| s.to_string());
```
and set `command_url` in the constructed struct. (Match the existing `from_config` construction style in the file.)

- [ ] **Step 4: POST from `send_command`**

At the top of `send_command` (before the `match`), add:
```rust
        if let Some(url) = &self.command_url {
            let verb = match command {
                PlayerCommand::Play => Some("play"),
                PlayerCommand::Pause => Some("pause"),
                PlayerCommand::Stop => Some("stop"),
                PlayerCommand::Next => Some("next"),
                PlayerCommand::Previous => Some("previous"),
                _ => None,
            };
            if let Some(verb) = verb {
                let body = format!("{{\"command\":\"{}\"}}", verb);
                let url = url.clone();
                // Fire-and-forget; a slow/absent daemon must not block the UI thread.
                std::thread::spawn(move || {
                    let _ = ureq::post(&url)
                        .set("Content-Type", "application/json")
                        .timeout(std::time::Duration::from_secs(2))
                        .send_string(&body);
                });
            }
        }
```
(Confirm `PlayerCommand::Next` / `Previous` variant names against `src/data/player_command.rs`; adjust if they differ.)

- [ ] **Step 5: Run to verify it passes**

Run: `cargo test --lib players::generic::tests::tests::test_command_url_posts_on_send_command`
Expected: PASS. Then run the full generic suite:
`cargo test --lib players::generic`
Expected: all generic tests PASS (backward compatibility intact).

- [ ] **Step 6: Bump version + changelog**

In `Cargo.toml`: `version = "0.7.15"`. Prepend to `debian/changelog`:
```
hifiberry-audiocontrol (0.7.15) trixie; urgency=medium

  * generic player: add optional command_url to POST transport commands to an
    external player (used by the Sendspin player).

 -- HiFiBerry <support@hifiberry.com>  Wed, 08 Jul 2026 12:00:00 +0000
```

- [ ] **Step 7: Commit (in the ACR repo)**

```bash
cd packages/acr/acr
git add -A && git commit -m "generic player: outbound command_url; v0.7.15"
git push origin main
```

---

### Task 18: hifiberry-os thin build wrapper (Component C)

**Files:**
- Create: `packages/sendspin/build.sh`
- Create: `packages/sendspin/clean.sh`
- Modify: `.gitignore` (add `packages/sendspin/sendspin`)

**Interfaces:**
- Consumes: the pushed `github.com/hifiberry/sendspin` repo.
- Produces: `packages/sendspin/build.sh` that clones/updates the repo and builds its `.deb` (acr/configurator pattern).

- [ ] **Step 1: Write `packages/sendspin/build.sh`**

```bash
#!/bin/bash
set -e
PACKAGE="sendspin"
REPO_URL="https://github.com/hifiberry/sendspin"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR"

if [[ "$1" == "--clean" ]]; then
    rm -rf "$PACKAGE"
    rm -f hifiberry-sendspin_*.deb hifiberry-sendspin_*.buildinfo hifiberry-sendspin_*.changes
    exit 0
fi

if [[ -d "$PACKAGE/.git" ]]; then
    echo "Updating $PACKAGE from $REPO_URL..."
    (cd "$PACKAGE" && git pull)
else
    echo "Cloning $PACKAGE from $REPO_URL..."
    git clone "$REPO_URL" "$PACKAGE"
fi

echo "Building the Debian package..."
chmod u+x "$PACKAGE/build.sh"
(cd "$PACKAGE" && ./build.sh)

# Collect the .deb next to this script
mv "$PACKAGE"/../hifiberry-sendspin_*.deb "$SCRIPT_DIR/" 2>/dev/null || \
  mv hifiberry-sendspin_*.deb "$SCRIPT_DIR/" 2>/dev/null || true
echo "Built packages:"
ls -lh "$SCRIPT_DIR"/hifiberry-sendspin_*.deb 2>/dev/null || echo "No packages found"
```

- [ ] **Step 2: Write `packages/sendspin/clean.sh`**

```bash
#!/bin/bash
cd "$(dirname "$0")"
rm -rf sendspin
rm -f hifiberry-sendspin_*.deb hifiberry-sendspin_*.buildinfo hifiberry-sendspin_*.changes
echo "Cleaned up sendspin build artifacts."
```

- [ ] **Step 3: Add the gitignore entry**

Append to the repo-root `.gitignore`:
```
packages/sendspin/sendspin
```

- [ ] **Step 4: Verify shell validity**

Run: `bash -n packages/sendspin/build.sh packages/sendspin/clean.sh && chmod +x packages/sendspin/build.sh packages/sendspin/clean.sh`
Expected: no syntax errors.

- [ ] **Step 5: Commit (in the hifiberry-os repo)**

```bash
git add packages/sendspin/build.sh packages/sendspin/clean.sh .gitignore
git commit -m "build(sendspin): thin clone+build wrapper for the sendspin player"
```

---

## Publish (after all tasks)

Once built and smoke-tested, publish both packages via the standard workflow (from `~/hifiberry-os/packages` on the build host): `./copy-packages` (pipe `yes y`), then `ssh matuschd@192.168.1.112 'bash -lc aptly-publish-public'`, then `apt install --only-upgrade hifiberry-audiocontrol` + `apt install hifiberry-sendspin` on tannoy. This is operational, not a plan task.

## Notes on integration risk

Tasks 8–13 integrate against `sendspin-cpp` (pinned `bf9e085`) and real ALSA/mDNS, which cannot be unit-tested off-device. Their correctness gate is: (a) the pure helpers they depend on are unit-tested (Tasks 2–8), (b) they compile clean on the build host, and (c) the Task 15 on-device smoke test verifies the end-to-end path. If `sendspin-cpp`'s API differs from the pinned commit's headers (e.g. `add_player` taking the config by value vs move, or `ServerPlayerStreamObject` field names), adjust the call sites — the header signatures in this plan are copied from commit `bf9e085`.

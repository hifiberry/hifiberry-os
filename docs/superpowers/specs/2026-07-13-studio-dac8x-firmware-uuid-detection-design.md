# Studio DAC8x firmware-UUID sound-card detection — design

**Goal:** Add firmware-UUID-based sound-card detection to the config-server
detection routine so that cards carrying an on-board controller firmware (the
HiFiBerry Studio DAC8x, and future firmware-based cards) are identified
primarily by the UUID they expose over I2C, with the existing HAT-EEPROM /
config.txt-overlay detection kept as a fallback.

**Component:** `packages/configurator/configurator` (the `configurator` Python
package that provides `config-server` / `config-soundcard`).

## Background

The HiFiBerry Studio DAC8x has an on-card controller MCU ("hb_controller")
reachable over I2C at **bus 1, address `0x10`**. Its firmware exposes a
register-addressed descriptor. The mainline kernel driver
`sound/soc/bcm/hifiberry_studio_dac8x.c`
(`raspberrypi/linux`, `rpi-6.18.y`) reads this descriptor; the relevant layout
(register offsets) is:

| Offset | Field |
|---|---|
| `0x00` | firmware_major |
| `0x01` | firmware_minor |
| `0x02` | firmware_subversion |
| `0x03` | hardware_major |
| `0x04` | hardware_minor |
| `0x05` | hardware_subversion |
| `0x10`–`0x1f` | UUID (16 bytes) |
| `0x28` | num_of_input_ch |
| `0x29` | num_of_output_ch |

The kernel exposes none of this via sysfs (it only logs to dmesg) and it holds
the I2C device (`1-0010`, named `hb_controller`) via `regmap_i2c`. A read-only
`i2cdump -y 1 0x10` succeeds while the driver is bound, so config-server can
read the descriptor directly over `/dev/i2c-1` without disturbing the driver.

Observed on the reference device (`192.168.1.97`, a CM5 with a Studio DAC8x):
firmware `V0.0.2`, hardware `V0.0.1`, UUID
`be3b8164dd7b48fcab2779dd7c641980`, 0 inputs / 8 outputs.

The kernel driver switches only on the **first 4 bytes** of the UUID
(`cpu_to_be32(*(u32*)&uuid)`), and only to rename the card to
"…Studio DAC8x Pro" when it is a clock provider — "Pro" is a runtime naming
variant, **not a separate card product**. There is exactly one firmware-based
card today: **Studio DAC8x**.

## Requirements

1. Read and parse the `hb_controller` firmware descriptor at I2C bus 1 / `0x10`.
2. Match the **full 16-byte UUID** (exact match) against a catalog of known
   firmware-based cards. On a match, that card's name and device-tree overlay
   are the detection result.
3. Run this as the **primary** detection step, before the existing
   HAT-EEPROM / config.txt-overlay / DSP detection.
4. If no descriptor is present, the UUID is unknown, or any read fails, fall
   back to the existing detection path **unchanged** (purely additive feature).
5. Must not disturb a bound kernel driver: read-only, single transactions.

## Architecture

Three touch points:

- **New module `configurator/hbcontroller.py`** — the I2C descriptor reader and
  parser. Isolated hardware I/O; no detection policy.
- **`configurator/soundcard.py`** — the card catalog gains a `firmware_uuid`
  field and a lookup helper. This keeps all card metadata (name, overlay,
  `aplay_contains`, `firmware_uuid`) in the single existing catalog.
- **`configurator/soundcard_detector.py`** — a new primary step at the top of
  `detect_card()` that uses the reader + catalog, then falls through.

### `hbcontroller.py`

```
UUID_REG      = 0x10
VERSION_REG   = 0x00
IN_CH_REG     = 0x28
OUT_CH_REG    = 0x29

@dataclass
class HbControllerDescriptor:
    firmware_version: str      # "0.0.2"
    hardware_version: str      # "0.0.1"
    uuid: str                  # "be3b8164dd7b48fcab2779dd7c641980" (lowercase hex, raw byte order)
    num_input_ch: int
    num_output_ch: int

def read_descriptor(bus: int = 1, addr: int = 0x10) -> HbControllerDescriptor | None
```

- Uses `smbus2`. Reads: 6 version bytes from `0x00`, 16 UUID bytes from `0x10`
  (via `read_i2c_block_data`, ≤32-byte SMBus block limit), and the two channel
  bytes from `0x28`/`0x29`.
- `uuid` is the raw 16 bytes rendered as lowercase hex with no separators —
  matching the kernel's dmesg form (`%*phN`) and the on-wire byte order, so the
  catalog string and the read string compare directly.
- Returns `None` on: `smbus2` not importable, `/dev/i2c-<bus>` absent, any
  `OSError` from the transfer (no device / NAK / short read), or an all-`0xff`
  read (floating bus). All failures logged at debug level.

### `soundcard.py`

Add a `firmware_uuid` key to the relevant catalog entry and a helper:

```
# In SOUND_CARD_DEFINITIONS — a new entry:
"Studio DAC8x": {
    "aplay_contains": "Studio DAC8x",
    "dtoverlay": "hifiberry-dac8x",
    "firmware_uuid": "be3b8164dd7b48fcab2779dd7c641980",
    ...
},

def card_by_firmware_uuid(uuid: str) -> tuple[str, dict] | None:
    """Return (card_name, definition) whose firmware_uuid equals uuid (exact,
    case-insensitive), else None."""
```

Decision: **"Studio DAC8x" is a new catalog entry** (matches the kernel's ALSA
card name and is distinct from the pre-existing `DAC8x` / `DAC8x/ADC8x`
entries), overlay `hifiberry-dac8x`. (If it should instead reuse the existing
`DAC8x` entry, that is a one-line change — attach `firmware_uuid` there.)

### `soundcard_detector.py`

At the very top of `detect_card()`:

```
desc = hbcontroller.read_descriptor(bus=1)
if desc:
    match = soundcard.card_by_firmware_uuid(desc.uuid)
    if match:
        card_name, definition = match
        self.detected_card = card_name
        self.detected_overlay = definition["dtoverlay"]
        log: "Detected <card_name> via firmware UUID <uuid> (fw <v>, hw <v>, <in>in/<out>out)"
        return  # primary detection succeeded; skip EEPROM/overlay path
# else: fall through to the existing detection unchanged
```

`_canonicalize_card_name()` / validators still apply where the existing flow
uses them; the firmware path sets a canonical catalog name directly so no
refinement is needed.

## Data flow

```
detect_card()
  └─ hbcontroller.read_descriptor(bus=1, 0x10)
       ├─ None (no firmware / read error) ─────────────► existing EEPROM/overlay/DSP detection
       └─ HbControllerDescriptor
            └─ soundcard.card_by_firmware_uuid(desc.uuid)
                 ├─ match  ─► set detected_card + detected_overlay, return (PRIMARY)
                 └─ no match ─────────────────────────► existing EEPROM/overlay/DSP detection
```

## Error handling / fallback

- Every failure mode of the reader yields `None` → existing detection runs.
- An unknown device answering at `0x10` (UUID not in catalog) → no match →
  existing detection runs (strict matching prevents false positives).
- Reads are read-only single transactions; safe alongside a bound driver.

## Testing

Unit tests (mock `smbus2.SMBus`):
- **Parse + match:** feed the captured `.97` register bytes; assert
  `firmware_version=="0.0.2"`, `hardware_version=="0.0.1"`,
  `uuid=="be3b8164dd7b48fcab2779dd7c641980"`, `num_input_ch==0`,
  `num_output_ch==8`; and that `card_by_firmware_uuid(uuid)` →
  `("Studio DAC8x", …)` with overlay `hifiberry-dac8x`.
- **Unknown UUID:** descriptor parses but UUID absent from catalog → detector
  falls back (does not set the card from firmware).
- **No device:** `SMBus` transfer raises `OSError` → `read_descriptor` returns
  `None` → detector falls back.
- **smbus2 absent:** import guarded → `read_descriptor` returns `None`.
- **Floating bus:** all-`0xff` read → `None`.

Integration: on `.97`, running the detector reports `Studio DAC8x` via the
firmware path (`detect_and_configure` dry-run / `store=False`).

## Assumptions

- The full 16-byte UUID is a **fixed per-model constant** — identical across all
  units of a model — so an exact-match registry generalizes across units. (The
  kernel checks only the 4-byte prefix; the full-UUID assumption is asserted
  from the firmware side.)
- The HAT controller firmware is on **I2C bus 1** (matches `i2c.py`'s default
  and the reference device). If a future Pi/CM variant uses a different HAT I2C
  bus, `read_descriptor`'s `bus` argument allows parameterizing it; not needed
  now.

## Out of scope

- Reading/using the extended descriptor fields beyond UUID + versions +
  channel counts (rates, formats, volume ranges, etc.) — the driver consumes
  those; config-server only needs identity here.
- Any change to the existing EEPROM/overlay/DSP detection behavior.

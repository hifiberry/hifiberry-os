# HAT EEPROM Library

This library provides functionality to read and write HAT EEPROM data using bitbanging I2C over GPIO pins with libgpiod.

HAT EEPROMs are typically 24C32 (4KB) I2C devices at address 0x50. They contain device tree overlay information and HAT identification data.

## Features

- Bitbang I2C implementation using libgpiod
- Support for multiple EEPROM types (24C32, 24C64, 24C128, 24C256)
- HAT specification compliant EEPROM parsing
- Vendor information extraction from ATOM 0x01
- Command-line tool and Python library

## Installation

```bash
pip install hateeprom
```

## Command Line Usage

```bash
# Detect HAT EEPROM
hateeprom detect

# Read HAT information
hateeprom info

# Read data from EEPROM
hateeprom read 0 100

# Write data to EEPROM
hateeprom write 0 "deadbeef"

# Dump entire EEPROM
hateeprom dump eeprom.bin

# Flash file to EEPROM
hateeprom flash myhat.eep
```

## Library Usage

```python
from hateeprom import HatEEPROM

# Initialize EEPROM interface
eeprom = HatEEPROM(i2c_addr=0x50, sda_pin=0, scl_pin=1)

# Check if EEPROM is available
if eeprom.is_available():
    print("HAT EEPROM detected")

# Read and parse HAT information
hat_info = eeprom.read_and_parse_hat()
if hat_info['valid']:
    vendor_info = hat_info['vendor_info']
    print(f"Vendor: {vendor_info['vendor']}")
    print(f"Product: {vendor_info['product']}")

# Read raw data
data = eeprom.read_data(0, 100)
if data:
    print(f"Read {len(data)} bytes")
```

## Requirements

- Python 3.7+
- python3-libgpiod
- gpiod
- libgpiod-dev

## License

MIT License

#!/usr/bin/env python3
"""
HAT EEPROM Library

This library provides functionality to read and write HAT EEPROM data using
bitbanging I2C over GPIO pins with libgpiod.

HAT EEPROMs are typically 24C32 (4KB) I2C devices at address 0x50.
They contain device tree overlay information and HAT identification data.
"""

from .bitbang_i2c import BitbangI2C
from .hat_eeprom import HatEEPROM

__version__ = "1.2.0"
__author__ = "HiFiBerry"
__all__ = ['BitbangI2C', 'HatEEPROM']

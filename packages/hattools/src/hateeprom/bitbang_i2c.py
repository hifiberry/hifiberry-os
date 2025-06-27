#!/usr/bin/env python3
"""
Bitbanging I2C implementation using libgpiod
"""

import time
import sys
from typing import Optional

try:
    import gpiod
except ImportError:
    print("Error: python3-libgpiod is required. Install with: sudo apt install python3-libgpiod")
    sys.exit(1)


class BitbangI2C:
    """Bitbanging I2C implementation using libgpiod"""
    
    def __init__(self, chip_name: str = "gpiochip0", sda_pin: int = 0, scl_pin: int = 1, delay: float = 0.00001):
        """
        Initialize I2C bitbang interface
        
        Args:
            chip_name: GPIO chip name (default: gpiochip0)
            sda_pin: SDA pin number (default: 0 - GPIO0)
            scl_pin: SCL pin number (default: 1 - GPIO1)  
            delay: Bit delay in seconds (default: 10us)
        """
        self.sda_pin = sda_pin
        self.scl_pin = scl_pin
        self.delay = delay
        
        try:
            self.chip = gpiod.Chip(chip_name)
            self.sda_line = self.chip.get_line(sda_pin)
            self.scl_line = self.chip.get_line(scl_pin)
            
            # Configure pins as outputs with pull-up (open drain simulation)
            self.sda_line.request(consumer="hateeprom", type=gpiod.LINE_REQ_DIR_OUT, default_val=1)
            self.scl_line.request(consumer="hateeprom", type=gpiod.LINE_REQ_DIR_OUT, default_val=1)
            
        except Exception as e:
            print(f"Error initializing GPIO: {e}")
            sys.exit(1)
    
    def __del__(self):
        """Cleanup GPIO resources"""
        try:
            if hasattr(self, 'sda_line'):
                self.sda_line.release()
            if hasattr(self, 'scl_line'):
                self.scl_line.release()
            if hasattr(self, 'chip'):
                self.chip.close()
        except:
            pass
    
    def _delay(self):
        """Small delay for I2C timing"""
        time.sleep(self.delay)
    
    def _sda_high(self):
        """Set SDA high (release - pull-up takes over)"""
        self.sda_line.set_value(1)
        self._delay()
    
    def _sda_low(self):
        """Set SDA low"""
        self.sda_line.set_value(0)
        self._delay()
    
    def _scl_high(self):
        """Set SCL high (release - pull-up takes over)"""
        self.scl_line.set_value(1)
        self._delay()
    
    def _scl_low(self):
        """Set SCL low"""
        self.scl_line.set_value(0)
        self._delay()
    
    def _read_sda(self) -> bool:
        """Read SDA pin state"""
        # Reconfigure as input to read
        self.sda_line.release()
        self.sda_line.request(consumer="hateeprom", type=gpiod.LINE_REQ_DIR_IN)
        value = self.sda_line.get_value()
        # Reconfigure back as output
        self.sda_line.release()
        self.sda_line.request(consumer="hateeprom", type=gpiod.LINE_REQ_DIR_OUT, default_val=1)
        return bool(value)
    
    def start_condition(self):
        """Generate I2C start condition"""
        self._sda_high()
        self._scl_high()
        self._sda_low()
        self._scl_low()
    
    def stop_condition(self):
        """Generate I2C stop condition"""
        self._sda_low()
        self._scl_high()
        self._sda_high()
    
    def write_bit(self, bit: bool):
        """Write a single bit"""
        if bit:
            self._sda_high()
        else:
            self._sda_low()
        self._scl_high()
        self._scl_low()
    
    def read_bit(self) -> bool:
        """Read a single bit"""
        self._sda_high()  # Release SDA for slave to drive
        self._scl_high()
        bit = self._read_sda()
        self._scl_low()
        return bit
    
    def write_byte(self, byte: int) -> bool:
        """
        Write a byte and return ACK/NACK
        
        Returns:
            True if ACK received, False if NACK
        """
        for i in range(7, -1, -1):
            self.write_bit((byte >> i) & 1)
        
        # Read ACK bit
        return not self.read_bit()  # ACK is low
    
    def read_byte(self, ack: bool = True) -> int:
        """
        Read a byte and send ACK/NACK
        
        Args:
            ack: Send ACK (True) or NACK (False)
            
        Returns:
            Byte value read
        """
        byte = 0
        for i in range(8):
            byte = (byte << 1) | (1 if self.read_bit() else 0)
        
        # Send ACK/NACK
        self.write_bit(not ack)  # ACK is low, NACK is high
        
        return byte

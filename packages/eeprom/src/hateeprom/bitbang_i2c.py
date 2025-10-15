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
    raise ImportError("python3-libgpiod is required. Install with: sudo apt install python3-libgpiod")


class BitbangI2C:
    """Bitbanging I2C implementation using libgpiod"""
    
    def __init__(self, chip_name: str = "gpiochip0", sda_pin: int = 0, scl_pin: int = 1, delay: float = 0.000005):
        """
        Initialize I2C bitbang interface
        
        Args:
            chip_name: GPIO chip name (default: gpiochip0)
            sda_pin: SDA pin number (default: 0 - GPIO0)
            scl_pin: SCL pin number (default: 1 - GPIO1)  
            delay: Bit delay in seconds (default: 5us for faster operation)
        """
        self.sda_pin = sda_pin
        self.scl_pin = scl_pin
        self.delay = delay
        
        # Detect gpiod version and use appropriate API
        self._detect_gpiod_version()
        
        try:
            # Handle both chip name and full device path
            if chip_name.startswith('/dev/'):
                chip_path = chip_name
            else:
                chip_path = f"/dev/{chip_name}"
            
            self.chip = gpiod.Chip(chip_path)
            
            if self.use_new_api:
                self._init_new_api()
            else:
                self._init_old_api()
                
        except Exception as e:
            raise IOError(f"Error initializing GPIO: {e}")
    
    def _detect_gpiod_version(self):
        """Detect which gpiod API version to use"""
        # Check for new API methods (gpiod 2.x)
        # The key difference is that new API doesn't have get_line method on Chip
        # and has LineSettings, request_lines function
        try:
            # Try to create a test chip to check available methods
            test_chip = gpiod.Chip('/dev/gpiochip0')
            self.use_new_api = not hasattr(test_chip, 'get_line')
            test_chip.close()
        except:
            # Fallback: check for new API classes and functions
            self.use_new_api = (
                hasattr(gpiod, 'LineSettings') and 
                hasattr(gpiod, 'request_lines')
            )
    
    def _init_new_api(self):
        """Initialize using new gpiod API (2.x)"""
        # Configure both pins as outputs with initial high state
        settings = gpiod.LineSettings(
            direction=gpiod.line.Direction.OUTPUT,
            output_value=gpiod.line.Value.ACTIVE
        )
        
        # Create line configuration dictionary
        line_config = {
            self.sda_pin: settings,
            self.scl_pin: settings
        }
        
        self.line_request = self.chip.request_lines(
            consumer="hateeprom",
            config=line_config
        )
    
    def _init_old_api(self):
        """Initialize using old gpiod API (1.x)"""
        self.sda_line = self.chip.get_line(self.sda_pin)
        self.scl_line = self.chip.get_line(self.scl_pin)
        
        # Configure pins as outputs with pull-up (open drain simulation)
        self.sda_line.request(consumer="hateeprom", type=gpiod.LINE_REQ_DIR_OUT, default_val=1)
        self.scl_line.request(consumer="hateeprom", type=gpiod.LINE_REQ_DIR_OUT, default_val=1)
    
    def __del__(self):
        """Cleanup GPIO resources"""
        try:
            if self.use_new_api:
                if hasattr(self, 'line_request'):
                    self.line_request.release()
            else:
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
        if self.use_new_api:
            self.line_request.set_value(self.sda_pin, gpiod.line.Value.ACTIVE)
        else:
            self.sda_line.set_value(1)
        self._delay()
    
    def _sda_low(self):
        """Set SDA low"""
        if self.use_new_api:
            self.line_request.set_value(self.sda_pin, gpiod.line.Value.INACTIVE)
        else:
            self.sda_line.set_value(0)
        self._delay()
    
    def _scl_high(self):
        """Set SCL high (release - pull-up takes over)"""
        if self.use_new_api:
            self.line_request.set_value(self.scl_pin, gpiod.line.Value.ACTIVE)
        else:
            self.scl_line.set_value(1)
        self._delay()
    
    def _scl_low(self):
        """Set SCL low"""
        if self.use_new_api:
            self.line_request.set_value(self.scl_pin, gpiod.line.Value.INACTIVE)
        else:
            self.scl_line.set_value(0)
        self._delay()
    
    def _read_sda(self) -> bool:
        """Read SDA pin state"""
        if self.use_new_api:
            # For new API, we need to reconfigure the line as input temporarily
            # Release current request and create a new one for reading
            self.line_request.release()
            
            # Create input configuration
            input_settings = gpiod.LineSettings(direction=gpiod.line.Direction.INPUT)
            input_config = {self.sda_pin: input_settings}
            
            # Request SDA line as input
            input_request = self.chip.request_lines(
                consumer="hateeprom-read",
                config=input_config
            )
            
            # Read the value
            value = input_request.get_value(self.sda_pin) == gpiod.line.Value.ACTIVE
            
            # Release input request
            input_request.release()
            
            # Restore original output configuration
            output_settings = gpiod.LineSettings(
                direction=gpiod.line.Direction.OUTPUT,
                output_value=gpiod.line.Value.ACTIVE
            )
            output_config = {
                self.sda_pin: output_settings,
                self.scl_pin: output_settings
            }
            self.line_request = self.chip.request_lines(
                consumer="hateeprom",
                config=output_config
            )
            
            return value
        else:
            # Old API - reconfigure as input to read
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

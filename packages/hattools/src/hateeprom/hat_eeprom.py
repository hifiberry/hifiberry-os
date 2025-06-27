#!/usr/bin/env python3
"""
HAT EEPROM interface using bitbang I2C
"""

import time
import struct
from typing import Optional

from .bitbang_i2c import BitbangI2C


class HatEEPROM:
    """HAT EEPROM interface using bitbang I2C"""
    
    def __init__(self, i2c_addr: int = 0x50, sda_pin: int = 0, scl_pin: int = 1):
        """
        Initialize HAT EEPROM interface
        
        Args:
            i2c_addr: I2C address (default: 0x50)
            sda_pin: SDA GPIO pin (default: 0)
            scl_pin: SCL GPIO pin (default: 1)
        """
        self.i2c_addr = i2c_addr
        self.i2c = BitbangI2C(sda_pin=sda_pin, scl_pin=scl_pin)
    
    def read_byte(self, address: int) -> Optional[int]:
        """Read a single byte from EEPROM"""
        try:
            # Start condition
            self.i2c.start_condition()
            
            # Write device address + write bit
            if not self.i2c.write_byte(self.i2c_addr << 1):
                raise Exception("Device not responding")
            
            # Write memory address (16-bit for 24C32)
            if not self.i2c.write_byte((address >> 8) & 0xFF):
                raise Exception("Address high byte NACK")
            if not self.i2c.write_byte(address & 0xFF):
                raise Exception("Address low byte NACK")
            
            # Repeated start
            self.i2c.start_condition()
            
            # Write device address + read bit
            if not self.i2c.write_byte((self.i2c_addr << 1) | 1):
                raise Exception("Read address NACK")
            
            # Read data byte
            data = self.i2c.read_byte(ack=False)  # NACK to end read
            
            # Stop condition
            self.i2c.stop_condition()
            
            return data
            
        except Exception as e:
            self.i2c.stop_condition()  # Ensure bus is released
            print(f"Read error at address 0x{address:04X}: {e}")
            return None
    
    def write_byte(self, address: int, data: int) -> bool:
        """Write a single byte to EEPROM"""
        try:
            # Start condition
            self.i2c.start_condition()
            
            # Write device address + write bit
            if not self.i2c.write_byte(self.i2c_addr << 1):
                raise Exception("Device not responding")
            
            # Write memory address (16-bit for 24C32)
            if not self.i2c.write_byte((address >> 8) & 0xFF):
                raise Exception("Address high byte NACK")
            if not self.i2c.write_byte(address & 0xFF):
                raise Exception("Address low byte NACK")
            
            # Write data byte
            if not self.i2c.write_byte(data):
                raise Exception("Data byte NACK")
            
            # Stop condition
            self.i2c.stop_condition()
            
            # Wait for write cycle to complete (typical 5ms for EEPROM)
            time.sleep(0.01)
            
            return True
            
        except Exception as e:
            self.i2c.stop_condition()  # Ensure bus is released
            print(f"Write error at address 0x{address:04X}: {e}")
            return False
    
    def read_data(self, start_addr: int, length: int) -> Optional[bytes]:
        """Read multiple bytes from EEPROM"""
        data = bytearray()
        
        for addr in range(start_addr, start_addr + length):
            byte = self.read_byte(addr)
            if byte is None:
                return None
            data.append(byte)
            
            # Progress indicator for large reads
            if length > 100 and (addr - start_addr) % 64 == 0:
                print(f"Read progress: {addr - start_addr}/{length} bytes")
        
        return bytes(data)
    
    def write_data(self, start_addr: int, data: bytes) -> bool:
        """Write multiple bytes to EEPROM"""
        for i, byte in enumerate(data):
            addr = start_addr + i
            if not self.write_byte(addr, byte):
                return False
            
            # Progress indicator for large writes
            if len(data) > 100 and i % 64 == 0:
                print(f"Write progress: {i}/{len(data)} bytes")
        
        return True
    
    def dump_eeprom(self, filename: str, size: int = 4096) -> bool:
        """Dump entire EEPROM to file"""
        print(f"Reading EEPROM ({size} bytes)...")
        data = self.read_data(0, size)
        
        if data is None:
            print("Failed to read EEPROM")
            return False
        
        try:
            with open(filename, 'wb') as f:
                f.write(data)
            print(f"EEPROM dumped to {filename}")
            return True
        except Exception as e:
            print(f"Error writing file: {e}")
            return False
    
    def write_eeprom(self, filename: str, offset: int = 0) -> bool:
        """Write file contents to EEPROM"""
        try:
            with open(filename, 'rb') as f:
                data = f.read()
        except Exception as e:
            print(f"Error reading file: {e}")
            return False
        
        print(f"Writing {len(data)} bytes to EEPROM at offset 0x{offset:04X}...")
        
        if self.write_data(offset, data):
            print("Write completed successfully")
            return True
        else:
            print("Write failed")
            return False
    
    def parse_hat_eeprom(self, data: bytes) -> dict:
        """
        Parse HAT EEPROM data according to HAT specification
        
        Args:
            data: Raw EEPROM data bytes
            
        Returns:
            Dictionary containing parsed HAT information
        """
        result = {
            'valid': False,
            'signature': None,
            'version': None,
            'vendor_info': {},
            'atoms': []
        }
        
        if len(data) < 12:
            result['error'] = 'EEPROM data too short'
            return result
        
        # Check HAT signature (should be "R-Pi" at offset 0)
        signature = data[0:4]
        if signature != b'R-Pi':
            result['error'] = f'Invalid HAT signature: {signature}'
            return result
        
        result['signature'] = signature.decode('ascii')
        result['version'] = data[4]
        
        # Skip reserved bytes and numatoms
        numatoms = struct.unpack('<H', data[6:8])[0]
        eeplen = struct.unpack('<L', data[8:12])[0]
        
        # Parse atoms starting at offset 12
        offset = 12
        atom_count = 0
        
        while offset < len(data) and atom_count < numatoms:
            if offset + 4 > len(data):
                break
                
            # Read atom header
            atom_type = struct.unpack('<H', data[offset:offset+2])[0]
            atom_count_field = struct.unpack('<H', data[offset+2:offset+4])[0]
            atom_dlen = atom_count_field & 0x7FFF  # Lower 15 bits
            
            atom_data = data[offset+4:offset+4+atom_dlen]
            
            atom_info = {
                'type': atom_type,
                'length': atom_dlen,
                'data': atom_data
            }
            
            # Parse ATOM 0x01 (Vendor info)
            if atom_type == 0x0001:
                atom_info['parsed'] = self._parse_vendor_atom(atom_data)
                result['vendor_info'] = atom_info['parsed']
            
            result['atoms'].append(atom_info)
            
            # Move to next atom (4 bytes header + data length)
            offset += 4 + atom_dlen
            atom_count += 1
        
        result['valid'] = True
        return result
    
    def _parse_vendor_atom(self, atom_data: bytes) -> dict:
        """
        Parse vendor information atom (ATOM 0x01)
        
        Args:
            atom_data: Raw atom data bytes
            
        Returns:
            Dictionary containing vendor information
        """
        vendor_info = {
            'uuid': None,
            'pid': None,
            'pver': None,
            'vendor': None,
            'product': None
        }
        
        if len(atom_data) < 22:  # Minimum: 16 bytes UUID + 2 bytes PID + 2 bytes PVER + 2 strings
            return vendor_info
        
        # Extract UUID (16 bytes)
        uuid_bytes = atom_data[0:16]
        vendor_info['uuid'] = uuid_bytes.hex()
        
        # Extract PID (2 bytes, little endian)
        vendor_info['pid'] = struct.unpack('<H', atom_data[16:18])[0]
        
        # Extract PVER (2 bytes, little endian)
        vendor_info['pver'] = struct.unpack('<H', atom_data[18:20])[0]
        
        # Extract vendor and product strings
        strings_data = atom_data[20:]
        
        # Find null-terminated strings
        strings = []
        current_string = bytearray()
        
        for byte in strings_data:
            if byte == 0:
                if current_string:
                    try:
                        strings.append(current_string.decode('ascii'))
                    except UnicodeDecodeError:
                        strings.append(current_string.decode('ascii', errors='replace'))
                    current_string = bytearray()
            else:
                current_string.append(byte)
        
        # Add final string if it doesn't end with null
        if current_string:
            try:
                strings.append(current_string.decode('ascii'))
            except UnicodeDecodeError:
                strings.append(current_string.decode('ascii', errors='replace'))
        
        # Assign vendor and product strings
        if len(strings) >= 1:
            vendor_info['vendor'] = strings[0]
        if len(strings) >= 2:
            vendor_info['product'] = strings[1]
        
        return vendor_info

    def read_and_parse_hat(self, size: int = None) -> dict:
        """
        Read and parse HAT EEPROM data
        
        Args:
            size: Number of bytes to read (default: auto-detect from type)
            
        Returns:
            Dictionary containing parsed HAT information
        """
        if size is None:
            size = 4096  # Default size
        
        data = self.read_data(0, size)
        if data is None:
            return {'valid': False, 'error': 'Failed to read EEPROM data'}
        
        return self.parse_hat_eeprom(data)

    def is_available(self) -> bool:
        """
        Check if HAT EEPROM is available and responding
        
        Returns:
            True if EEPROM responds, False otherwise
        """
        try:
            # Try to read a single byte from address 0
            # This is a non-destructive way to test communication
            self.i2c.start_condition()
            
            # Write device address + write bit
            if not self.i2c.write_byte(self.i2c_addr << 1):
                self.i2c.stop_condition()
                return False
            
            # Write memory address 0x0000
            if not self.i2c.write_byte(0x00):
                self.i2c.stop_condition()
                return False
            if not self.i2c.write_byte(0x00):
                self.i2c.stop_condition()
                return False
            
            # Repeated start for read
            self.i2c.start_condition()
            
            # Write device address + read bit
            if not self.i2c.write_byte((self.i2c_addr << 1) | 1):
                self.i2c.stop_condition()
                return False
            
            # Read one byte (don't care about the value)
            self.i2c.read_byte(ack=False)  # NACK to end read
            
            # Stop condition
            self.i2c.stop_condition()
            
            return True
            
        except Exception:
            try:
                self.i2c.stop_condition()  # Ensure bus is released
            except:
                pass
            return False

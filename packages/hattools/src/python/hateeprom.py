#!/usr/bin/env python3
"""
HAT EEPROM Reader/Writer Tool

This tool provides functionality to read and write HAT EEPROM data using
bitbanging I2C over GPIO pins with libgpiod.

HAT EEPROMs are typically 24C32 (4KB) I2C devices at address 0x50.
They contain device tree overlay information and HAT identification data.
"""

import argparse
import sys
import time
import struct
from typing import Optional, List

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


def main():
    parser = argparse.ArgumentParser(description="HAT EEPROM Reader/Writer Tool")
    parser.add_argument('--sda', type=int, default=0, help='SDA GPIO pin (default: 0)')
    parser.add_argument('--scl', type=int, default=1, help='SCL GPIO pin (default: 1)')
    parser.add_argument('--addr', type=lambda x: int(x, 0), default=0x50, help='I2C address (default: 0x50)')
    parser.add_argument('--type', choices=['24c32', '24c64', '24c128', '24c256'], default='24c32', 
                       help='EEPROM type (default: 24c32)')
    
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    
    # Read command
    read_parser = subparsers.add_parser('read', help='Read from EEPROM')
    read_parser.add_argument('address', type=lambda x: int(x, 0), help='Start address (hex or decimal)')
    read_parser.add_argument('length', type=int, help='Number of bytes to read')
    read_parser.add_argument('--output', '-o', help='Output file (optional)')
    
    # Write command
    write_parser = subparsers.add_parser('write', help='Write to EEPROM')
    write_parser.add_argument('address', type=lambda x: int(x, 0), help='Start address (hex or decimal)')
    write_parser.add_argument('data', help='Data to write (hex string or file path)')
    
    # Dump command
    dump_parser = subparsers.add_parser('dump', help='Dump entire EEPROM')
    dump_parser.add_argument('filename', help='Output filename')
    dump_parser.add_argument('--size', type=int, help='EEPROM size in bytes (default: auto-detect from type)')
    
    # Flash command
    flash_parser = subparsers.add_parser('flash', help='Flash file to EEPROM')
    flash_parser.add_argument('filename', help='Input filename')
    flash_parser.add_argument('--offset', type=lambda x: int(x, 0), default=0, help='Write offset (default: 0)')
    
    # Detect command
    detect_parser = subparsers.add_parser('detect', help='Detect if HAT EEPROM is available')
    detect_parser.add_argument('--quiet', '-q', action='store_true', help='Quiet mode - no output, only return code')
    
    # Info command
    info_parser = subparsers.add_parser('info', help='Display HAT information from EEPROM')
    info_parser.add_argument('--size', type=int, help='EEPROM size in bytes (default: auto-detect from type)')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    # Get EEPROM size based on type
    eeprom_sizes = {
        '24c32': 4096,    # 4KB
        '24c64': 8192,    # 8KB
        '24c128': 16384,  # 16KB
        '24c256': 32768   # 32KB
    }
    eeprom_size = eeprom_sizes[args.type]
    
    # Initialize EEPROM interface
    eeprom = HatEEPROM(i2c_addr=args.addr, sda_pin=args.sda, scl_pin=args.scl)
    
    if args.command == 'read':
        # Validate read bounds
        if args.address + args.length > eeprom_size:
            print(f"Error: Read operation would exceed EEPROM size ({eeprom_size} bytes for {args.type})")
            return 1
            
        data = eeprom.read_data(args.address, args.length)
        if data is None:
            return 1
        
        if args.output:
            try:
                with open(args.output, 'wb') as f:
                    f.write(data)
                print(f"Data written to {args.output}")
            except Exception as e:
                print(f"Error writing file: {e}")
                return 1
        else:
            # Print hex dump
            for i in range(0, len(data), 16):
                hex_bytes = ' '.join(f'{b:02X}' for b in data[i:i+16])
                ascii_chars = ''.join(chr(b) if 32 <= b <= 126 else '.' for b in data[i:i+16])
                print(f'{args.address + i:04X}: {hex_bytes:<48} {ascii_chars}')
    
    elif args.command == 'write':
        # Check if data is a file path or hex string
        try:
            with open(args.data, 'rb') as f:
                data = f.read()
        except:
            # Treat as hex string
            try:
                data = bytes.fromhex(args.data.replace(' ', '').replace('0x', ''))
            except ValueError:
                print("Error: Data must be a valid hex string or file path")
                return 1
        
        # Validate write bounds
        if args.address + len(data) > eeprom_size:
            print(f"Error: Write operation would exceed EEPROM size ({eeprom_size} bytes for {args.type})")
            return 1
        
        if not eeprom.write_data(args.address, data):
            return 1
    
    elif args.command == 'dump':
        dump_size = args.size if args.size else eeprom_size
        if not eeprom.dump_eeprom(args.filename, dump_size):
            return 1
    
    elif args.command == 'flash':
        # Read file first to check size
        try:
            with open(args.filename, 'rb') as f:
                file_data = f.read()
        except Exception as e:
            print(f"Error reading file: {e}")
            return 1
        
        # Validate flash bounds
        if args.offset + len(file_data) > eeprom_size:
            print(f"Error: Flash operation would exceed EEPROM size ({eeprom_size} bytes for {args.type})")
            return 1
        
        if not eeprom.write_eeprom(args.filename, args.offset):
            return 1
    
    elif args.command == 'detect':
        if not args.quiet:
            print(f"Checking for HAT EEPROM at address 0x{args.addr:02X} on GPIO pins SDA={args.sda}, SCL={args.scl}...")
        if eeprom.is_available():
            if not args.quiet:
                print("HAT EEPROM detected and responding")
            return 0
        else:
            if not args.quiet:
                print("No HAT EEPROM detected or device not responding")
            return 1
    
    elif args.command == 'info':
        info_size = args.size if args.size else eeprom_size
        hat_info = eeprom.read_and_parse_hat(info_size)
        
        if not hat_info['valid']:
            print(f"Error: {hat_info.get('error', 'Invalid HAT EEPROM data')}")
            return 1
        
        print("HAT EEPROM Information:")
        print(f"  Signature: {hat_info['signature']}")
        print(f"  Version: {hat_info['version']}")
        print(f"  Atoms found: {len(hat_info['atoms'])}")
        
        if hat_info['vendor_info']:
            vi = hat_info['vendor_info']
            print("\nVendor Information (ATOM 0x01):")
            print(f"  UUID: {vi.get('uuid', 'N/A')}")
            print(f"  Product ID: 0x{vi.get('pid', 0):04X}")
            print(f"  Product Version: 0x{vi.get('pver', 0):04X}")
            print(f"  Vendor: {vi.get('vendor', 'N/A')}")
            print(f"  Product: {vi.get('product', 'N/A')}")
        
        # Display other atoms
        for atom in hat_info['atoms']:
            if atom['type'] != 0x0001:  # Skip vendor info atom (already displayed)
                print(f"\nATOM 0x{atom['type']:04X}:")
                print(f"  Length: {atom['length']} bytes")
                # Show first 32 bytes of data as hex
                data_preview = atom['data'][:32]
                hex_data = ' '.join(f'{b:02X}' for b in data_preview)
                if len(atom['data']) > 32:
                    hex_data += '...'
                print(f"  Data: {hex_data}")
    
    return 0


if __name__ == '__main__':
    sys.exit(main())

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
        """Read multiple bytes from EEPROM using optimized page reads"""
        data = bytearray()
        
        # Read in chunks to optimize I2C transactions
        # Most EEPROMs support sequential reads
        remaining = length
        current_addr = start_addr
        
        while remaining > 0:
            # Read up to 32 bytes at a time (common EEPROM page size)
            chunk_size = min(32, remaining)
            
            try:
                # Start condition
                self.i2c.start_condition()
                
                # Write device address + write bit
                if not self.i2c.write_byte(self.i2c_addr << 1):
                    raise Exception("Device not responding")
                
                # Write memory address (16-bit)
                if not self.i2c.write_byte((current_addr >> 8) & 0xFF):
                    raise Exception("Address high byte NACK")
                if not self.i2c.write_byte(current_addr & 0xFF):
                    raise Exception("Address low byte NACK")
                
                # Repeated start for read
                self.i2c.start_condition()
                
                # Write device address + read bit
                if not self.i2c.write_byte((self.i2c_addr << 1) | 1):
                    raise Exception("Read address NACK")
                
                # Read multiple bytes sequentially
                chunk_data = bytearray()
                for i in range(chunk_size):
                    # Send ACK for all bytes except the last one
                    ack = (i < chunk_size - 1)
                    byte_data = self.i2c.read_byte(ack=ack)
                    chunk_data.append(byte_data)
                
                # Stop condition
                self.i2c.stop_condition()
                
                data.extend(chunk_data)
                current_addr += chunk_size
                remaining -= chunk_size
                
                # Progress indicator for large reads
                if length > 100 and (current_addr - start_addr) % 128 == 0:
                    print(f"Read progress: {current_addr - start_addr}/{length} bytes")
                
            except Exception as e:
                self.i2c.stop_condition()  # Ensure bus is released
                print(f"Read error at address 0x{current_addr:04X}: {e}")
                return None
        
        return bytes(data)
    
    def write_data(self, start_addr: int, data: bytes) -> bool:
        """Write multiple bytes to EEPROM using page writes where possible"""
        remaining = len(data)
        current_addr = start_addr
        data_offset = 0
        
        while remaining > 0:
            # Calculate page boundary - most EEPROMs have 32-byte pages
            page_size = 32
            page_start = (current_addr // page_size) * page_size
            bytes_to_page_end = page_size - (current_addr - page_start)
            
            # Don't cross page boundaries and don't exceed remaining data
            chunk_size = min(bytes_to_page_end, remaining, 16)  # Conservative chunk size
            
            # Write single byte for compatibility
            if not self.write_byte(current_addr, data[data_offset]):
                return False
            
            current_addr += 1
            data_offset += 1
            remaining -= 1
            
            # Progress indicator for large writes
            if len(data) > 100 and data_offset % 64 == 0:
                print(f"Write progress: {data_offset}/{len(data)} bytes")
        
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
    
    def parse_hat_eeprom(self, data: bytes, debug: bool = False) -> dict:
        """
        Parse HAT EEPROM data according to the official format
        Based on official Raspberry Pi eeptools/eeplib.c
        
        Args:
            data: Raw EEPROM data bytes
            debug: Enable debug output for parsing
            
        Returns:
            Dictionary containing parsed HAT information
        """
        result = {
            'valid': False,
            'header': {},
            'atoms': [],
            'vendor_info': {}
        }
        
        if len(data) < 12:
            result['error'] = 'Data too short for header'
            return result
        
        # Parse EEPROM header (first 12 bytes)
        try:
            # Signature should be "R-Pi" (0x52-50-69 in little endian becomes 0x69502d52)
            signature = struct.unpack('<I', data[0:4])[0]
            ver = data[4]
            res = data[5]
            numatoms = struct.unpack('<H', data[6:8])[0]
            eeplen = struct.unpack('<I', data[8:12])[0]
            
            result['header'] = {
                'signature': f"0x{signature:08X}",
                'version': ver,
                'reserved': res,
                'num_atoms': numatoms,
                'eep_length': eeplen
            }
            
            if debug:
                print(f"Debug: Header: signature=0x{signature:08X}, ver={ver}, atoms={numatoms}, len={eeplen}")
            
            # Check signature (should be 0x69502d52 for "R-Pi")
            if signature != 0x69502d52:
                result['error'] = f'Invalid signature: expected 0x69502d52, got 0x{signature:08X}'
                if debug:
                    print(f"Debug: Invalid signature, but continuing parsing...")
                # Continue parsing anyway for analysis
        
        except struct.error as e:
            result['error'] = f'Header parsing error: {e}'
            return result
        
        # Parse atoms starting at offset 12
        offset = 12
        atom_count = 0
        
        while offset < len(data) and atom_count < result['header']['num_atoms']:
            if offset + 8 > len(data):  # Need at least 8 bytes for atom header
                break
            
            # Parse atom header (8 bytes total):
            # type (2 bytes) + count (2 bytes) + dlen (4 bytes)
            atom_type = struct.unpack('<H', data[offset:offset+2])[0]
            atom_seq = struct.unpack('<H', data[offset+2:offset+4])[0]
            atom_dlen = struct.unpack('<I', data[offset+4:offset+8])[0]
            
            if debug:
                print(f"Debug: Atom header at offset {offset}: {data[offset:offset+8].hex()}")
                print(f"Debug: type=0x{atom_type:04X}, seq={atom_seq}, dlen={atom_dlen}")
            
            # Atom data length includes 2-byte CRC, so actual data is dlen-2
            if atom_dlen < 2:
                if debug:
                    print(f"Warning: Invalid atom data length {atom_dlen}")
                break
                
            data_len = atom_dlen - 2  # Subtract CRC length
            
            # Ensure we don't read beyond the data
            if offset + 8 + atom_dlen > len(data):
                if debug:
                    print(f"Warning: Atom {atom_count} total length {8 + atom_dlen} exceeds available data")
                break
            
            # Extract atom data (excluding CRC)
            atom_data = data[offset+8:offset+8+data_len]
            
            # Extract CRC (last 2 bytes of atom)
            atom_crc = struct.unpack('<H', data[offset+8+data_len:offset+8+atom_dlen])[0]
            
            atom_info = {
                'type': atom_type,
                'sequence': atom_seq,
                'data_length': data_len,
                'total_length': atom_dlen,
                'crc': atom_crc,
                'data': atom_data
            }
            
            # Debug output for atom parsing
            if debug:
                print(f"Debug: Atom {atom_count}: type=0x{atom_type:04X}, seq={atom_seq}, data_len={data_len}, crc=0x{atom_crc:04X}")
                if len(atom_data) > 0:
                    preview = atom_data[:16].hex() if len(atom_data) >= 16 else atom_data.hex()
                    print(f"Debug: Atom data preview: {preview}")
            
            # Parse ATOM 0x01 (Vendor info)
            if atom_type == 0x0001:
                atom_info['parsed'] = self._parse_vendor_atom(atom_data, debug=debug)
                result['vendor_info'] = atom_info['parsed']
            
            result['atoms'].append(atom_info)
            
            # Move to next atom (8 bytes header + data + CRC)
            offset += 8 + atom_dlen
            atom_count += 1
        
        result['valid'] = True
        return result
    
    def _parse_vendor_atom(self, atom_data: bytes, debug: bool = False) -> dict:
        """
        Parse vendor information atom (ATOM 0x01)
        Based on official Raspberry Pi eeptools format:
        - serial[4] (16 bytes): UUID as 4 uint32_t values 
        - pid (2 bytes): product ID
        - pver (2 bytes): product version
        - vslen (1 byte): vendor string length
        - pslen (1 byte): product string length
        - vstr (vslen bytes): vendor string
        - pstr (pslen bytes): product string
        
        Args:
            atom_data: Raw atom data bytes
            debug: Enable debug output
            
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
        
        if len(atom_data) < 22:  # Minimum: 16 bytes UUID + 2 bytes PID + 2 bytes PVER + 1 byte vslen + 1 byte pslen
            if debug:
                print(f"Warning: Vendor atom too short ({len(atom_data)} bytes), expected at least 22")
            return vendor_info
        
        # Extract UUID (16 bytes as 4 uint32_t little-endian values)
        uuid_parts = struct.unpack('<4I', atom_data[0:16])
        # Format as standard UUID string: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
        vendor_info['uuid'] = f"{uuid_parts[3]:08x}-{(uuid_parts[2] >> 16):04x}-{(uuid_parts[2] & 0xffff):04x}-{(uuid_parts[1] >> 16):04x}-{(uuid_parts[1] & 0xffff):04x}{uuid_parts[0]:08x}"
        
        # Extract PID (2 bytes, little endian)  
        vendor_info['pid'] = struct.unpack('<H', atom_data[16:18])[0]
        
        # Extract PVER (2 bytes, little endian)
        vendor_info['pver'] = struct.unpack('<H', atom_data[18:20])[0]
        
        # Extract string lengths
        vslen = atom_data[20]  # vendor string length
        pslen = atom_data[21]  # product string length
        
        if debug:
            print(f"Debug: Vendor atom - vslen={vslen}, pslen={pslen}")
        
        # Extract vendor string (if present)
        if vslen > 0 and len(atom_data) >= 22 + vslen:
            vendor_str_data = atom_data[22:22+vslen]
            try:
                vendor_info['vendor'] = vendor_str_data.decode('ascii').rstrip('\x00')
            except UnicodeDecodeError:
                vendor_info['vendor'] = vendor_str_data.decode('ascii', errors='replace').rstrip('\x00')
        
        # Extract product string (if present)
        if pslen > 0 and len(atom_data) >= 22 + vslen + pslen:
            product_str_data = atom_data[22+vslen:22+vslen+pslen]
            try:
                vendor_info['product'] = product_str_data.decode('ascii').rstrip('\x00')
            except UnicodeDecodeError:
                vendor_info['product'] = product_str_data.decode('ascii', errors='replace').rstrip('\x00')
        
        if debug:
            print(f"Debug: Parsed vendor info: {vendor_info}")
        
        return vendor_info

    def read_and_parse_hat(self, size: int = None, debug: bool = False, vendor_only: bool = False) -> dict:
        """
        Read and parse HAT EEPROM data efficiently
        By default uses incremental reading (atom by atom), but can fallback to bulk read
        
        Args:
            size: If specified, uses bulk read with this size; otherwise uses incremental read
            debug: Enable debug output for parsing
            vendor_only: If True, stop after finding and parsing the vendor atom (only works with incremental read)
            
        Returns:
            Dictionary containing parsed HAT information
        """
        if size is None:
            # Use incremental reading by default (more efficient)
            return self.read_and_parse_hat_incremental(debug=debug, vendor_only=vendor_only)
        else:
            # Use bulk reading when size is specified (vendor_only not supported for bulk read)
            return self.read_and_parse_hat_bulk(size, debug=debug)
    
    def read_and_parse_hat_bulk(self, size: int, debug: bool = False) -> dict:
        """
        Read and parse HAT EEPROM data using bulk read
        Reads the specified amount of data at once, then parses it
        
        Args:
            size: Number of bytes to read
            debug: Enable debug output for parsing
            
        Returns:
            Dictionary containing parsed HAT information
        """
        # First, read the header (12 bytes) to get EEPROM length if size not specified
        if size == 0:
            header_data = self.read_data(0, 12)
            if header_data is None:
                return {'valid': False, 'error': 'Failed to read EEPROM header'}
            
            try:
                eeplen = struct.unpack('<I', header_data[8:12])[0]
                size = min(eeplen, 8192)  # Cap at 8KB for safety
                if debug:
                    print(f"Debug: Auto-detected size from header: {size} bytes")
            except struct.error:
                size = 4096  # Fallback default
        
        # Read the data
        data = self.read_data(0, size)
        if data is None:
            return {'valid': False, 'error': 'Failed to read EEPROM data'}
        
        return self.parse_hat_eeprom(data, debug=debug)

    def read_and_parse_hat_incremental(self, debug: bool = False, vendor_only: bool = False) -> dict:
        """
        Read and parse HAT EEPROM data incrementally, atom by atom
        This is more efficient as it only reads what's needed for each atom
        
        Args:
            debug: Enable debug output for parsing
            vendor_only: If True, stop after finding and parsing the vendor atom (ATOM 0x01)
            
        Returns:
            Dictionary containing parsed HAT information
        """
        result = {
            'valid': False,
            'header': {},
            'atoms': [],
            'vendor_info': {}
        }
        
        # Read header (12 bytes)
        header_data = self.read_data(0, 12)
        if header_data is None:
            return {'valid': False, 'error': 'Failed to read EEPROM header'}
        
        if len(header_data) < 12:
            return {'valid': False, 'error': 'Header data too short'}
        
        # Parse header
        try:
            signature = struct.unpack('<I', header_data[0:4])[0]
            ver = header_data[4]
            res = header_data[5]
            numatoms = struct.unpack('<H', header_data[6:8])[0]
            eeplen = struct.unpack('<I', header_data[8:12])[0]
            
            result['header'] = {
                'signature': f"0x{signature:08X}",
                'version': ver,
                'reserved': res,
                'num_atoms': numatoms,
                'eep_length': eeplen
            }
            
            if debug:
                print(f"Debug: Header: signature=0x{signature:08X}, ver={ver}, atoms={numatoms}, len={eeplen}")
            
            # Check signature (should be 0x69502d52 for "R-Pi")
            if signature != 0x69502d52:
                result['error'] = f'Invalid signature: expected 0x69502d52, got 0x{signature:08X}'
                if debug:
                    print(f"Debug: Invalid signature, but continuing parsing...")
        
        except struct.error as e:
            result['error'] = f'Header parsing error: {e}'
            return result
        
        # Parse atoms incrementally
        offset = 12
        atom_count = 0
        
        while atom_count < result['header']['num_atoms']:
            # Read atom header (8 bytes)
            atom_header_data = self.read_data(offset, 8)
            if atom_header_data is None or len(atom_header_data) < 8:
                if debug:
                    print(f"Warning: Failed to read atom {atom_count} header at offset {offset}")
                break
            
            # Parse atom header
            atom_type = struct.unpack('<H', atom_header_data[0:2])[0]
            atom_seq = struct.unpack('<H', atom_header_data[2:4])[0]
            atom_dlen = struct.unpack('<I', atom_header_data[4:8])[0]
            
            if debug:
                print(f"Debug: Atom {atom_count}: type=0x{atom_type:04X}, seq={atom_seq}, dlen={atom_dlen} at offset {offset}")
            
            # Validate atom data length
            if atom_dlen < 2:
                if debug:
                    print(f"Warning: Invalid atom data length {atom_dlen}")
                break
            
            data_len = atom_dlen - 2  # Subtract CRC length
            
            # Read atom data + CRC
            atom_payload = self.read_data(offset + 8, atom_dlen)
            if atom_payload is None or len(atom_payload) < atom_dlen:
                if debug:
                    print(f"Warning: Failed to read atom {atom_count} data at offset {offset + 8}")
                break
            
            # Extract atom data (excluding CRC)
            atom_data = atom_payload[:data_len]
            
            # Extract CRC (last 2 bytes)
            atom_crc = struct.unpack('<H', atom_payload[data_len:data_len+2])[0]
            
            atom_info = {
                'type': atom_type,
                'sequence': atom_seq,
                'data_length': data_len,
                'total_length': atom_dlen,
                'crc': atom_crc,
                'data': atom_data
            }
            
            if debug:
                preview = atom_data[:16].hex() if len(atom_data) >= 16 else atom_data.hex()
                print(f"Debug: Atom data preview: {preview}")
            
            # Parse ATOM 0x01 (Vendor info)
            if atom_type == 0x0001:
                atom_info['parsed'] = self._parse_vendor_atom(atom_data, debug=debug)
                result['vendor_info'] = atom_info['parsed']
            
            result['atoms'].append(atom_info)
            
            # Move to next atom
            offset += 8 + atom_dlen
            atom_count += 1
            
            # Early exit optimization: if we only need vendor info and found it, we can stop
            if vendor_only and atom_type == 0x0001:
                if debug:
                    print(f"Debug: Found vendor atom, stopping early (vendor_only=True)")
                break
        
        result['valid'] = True
        return result

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
    
    def short_info(self, debug: bool = False) -> dict:
        """
        Get concise HAT information (vendor info only)
        This is optimized for efficiency and stops after reading the vendor atom
        
        Args:
            debug: Enable debug output for parsing
            
        Returns:
            Dictionary with keys: 'success', 'vendor', 'product', 'uuid', 'pid', 'pver'
            If unsuccessful, 'success' is False and 'error' contains the error message
        """
        result = {
            'success': False,
            'vendor': 'Unknown',
            'product': 'Unknown', 
            'uuid': 'Unknown',
            'pid': None,
            'pver': None,
            'error': None
        }
        
        try:
            # Use incremental reading with vendor_only=True for maximum efficiency
            hat_info = self.read_and_parse_hat(size=None, debug=debug, vendor_only=True)
            
            if hat_info is None:
                result['error'] = 'Failed to read EEPROM data'
                return result
                
            if not hat_info['valid']:
                result['error'] = hat_info.get('error', 'Invalid HAT EEPROM data')
                return result
            
            # Extract vendor information if available
            if hat_info.get('vendor_info'):
                vi = hat_info['vendor_info']
                result['success'] = True
                result['vendor'] = vi.get('vendor', 'Unknown')
                result['product'] = vi.get('product', 'Unknown')
                result['uuid'] = vi.get('uuid', 'Unknown')
                result['pid'] = vi.get('pid')
                result['pver'] = vi.get('pver')
            else:
                result['error'] = 'No vendor information found in HAT EEPROM'
                
        except Exception as e:
            result['error'] = f'Exception during HAT info read: {str(e)}'
            
        return result
    
    def format_short_info(self, separator: str = ':', debug: bool = False) -> str:
        """
        Get HAT information as a formatted string
        
        Args:
            separator: String to use between vendor, product, and uuid (default: ':')
            debug: Enable debug output for parsing
            
        Returns:
            Formatted string: "vendor{separator}product{separator}uuid"
            Returns "Unknown{separator}Unknown{separator}Unknown" if no info found
            Returns "ERROR{separator}{error_message}" if an error occurs
        """
        info = self.short_info(debug=debug)
        
        if not info['success']:
            return f"ERROR{separator}{info.get('error', 'Unknown error')}"
        
        return f"{info['vendor']}{separator}{info['product']}{separator}{info['uuid']}"

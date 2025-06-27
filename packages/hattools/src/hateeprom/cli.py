#!/usr/bin/env python3
"""
HAT EEPROM Command Line Tool

Command-line interface for the hateeprom library.
"""

import argparse
import sys
import struct

from hateeprom import HatEEPROM


def _get_atom_type_name(atom_type):
    """Get human-readable name for atom type"""
    atom_names = {
        0x0000: "Invalid",
        0x0001: "Vendor Info",
        0x0002: "GPIO Bank 0 Map",
        0x0003: "Device Tree Blob",
        0x0004: "Manufacturer Custom Data",
        0x0005: "GPIO Bank 1 Map",
        0xFFFF: "Invalid"
    }
    return atom_names.get(atom_type, f"Unknown (0x{atom_type:04X})")


def _display_vendor_atom(vendor_info):
    """Display vendor atom information"""
    print(f"    Vendor Information:")
    print(f"      UUID: {vendor_info.get('uuid', 'N/A')}")
    
    pid = vendor_info.get('pid')
    if pid is not None:
        print(f"      Product ID: 0x{pid:04X}")
    else:
        print("      Product ID: N/A")
    
    pver = vendor_info.get('pver')
    if pver is not None:
        print(f"      Product Version: 0x{pver:04X}")
    else:
        print("      Product Version: N/A")
        
    print(f"      Vendor: {vendor_info.get('vendor', 'N/A')}")
    print(f"      Product: {vendor_info.get('product', 'N/A')}")


def _display_gpio_bank0_atom(data):
    """Display GPIO bank 0 atom information"""
    if len(data) < 30:
        print(f"    GPIO Bank 0: Invalid data length ({len(data)} bytes, expected 30)")
        return
    
    bank_drive = data[0]
    power = data[1]
    
    drive = bank_drive & 0x0F
    slew = (bank_drive >> 4) & 0x03
    hysteresis = (bank_drive >> 6) & 0x03
    
    back_power = power & 0x03
    
    print(f"    GPIO Bank 0 Configuration:")
    print(f"      Drive strength: {drive} ({'default' if drive == 0 else f'{drive*2}mA'})")
    print(f"      Slew rate: {slew} ({'default' if slew == 0 else 'limiting' if slew == 1 else 'no limiting' if slew == 2 else 'reserved'})")
    print(f"      Hysteresis: {hysteresis} ({'default' if hysteresis == 0 else 'disabled' if hysteresis == 1 else 'enabled' if hysteresis == 2 else 'reserved'})")
    print(f"      Back power: {back_power} ({'none' if back_power == 0 else '1.3A' if back_power == 1 else '2A' if back_power == 2 else 'reserved'})")
    
    print(f"      GPIO Pin Configuration:")
    for i in range(28):
        gpio_byte = data[2 + i]
        func_sel = gpio_byte & 0x07
        pulltype = (gpio_byte >> 5) & 0x03
        is_used = (gpio_byte >> 7) & 0x01
        
        if is_used:
            pull_str = ['default', 'pullup', 'pulldown', 'no pull'][pulltype]
            print(f"        GPIO {i}: Function {func_sel}, Pull: {pull_str}")


def _display_device_tree_atom(data):
    """Display Device Tree atom information"""
    print(f"    Device Tree Blob:")
    print(f"      Size: {len(data)} bytes")
    if len(data) > 0:
        # Try to detect if it's a DTB file or overlay name
        if data.startswith(b'\xd0\x0d\xfe\xed'):  # DTB magic number
            print(f"      Type: Compiled Device Tree Binary")
        elif all(32 <= b <= 126 for b in data[:min(len(data), 64)]):  # Printable ASCII
            try:
                content = data.decode('ascii').strip('\x00')
                print(f"      Content: {content}")
            except:
                print(f"      Content: Binary data")
        else:
            print(f"      Type: Binary data")
            print(f"      Preview: {data[:16].hex()}")


def _display_custom_data_atom(data):
    """Display manufacturer custom data atom"""
    print(f"    Manufacturer Custom Data:")
    print(f"      Size: {len(data)} bytes")
    if len(data) > 0:
        # Try to display as text if it looks like ASCII
        if all(32 <= b <= 126 or b in [9, 10, 13] for b in data[:min(len(data), 64)]):
            try:
                content = data.decode('ascii', errors='ignore').strip('\x00')
                if content:
                    print(f"      Text content: {content}")
                else:
                    print(f"      Binary data preview: {data[:16].hex()}")
            except:
                print(f"      Binary data preview: {data[:16].hex()}")
        else:
            print(f"      Binary data preview: {data[:16].hex()}")


def _display_gpio_bank1_atom(data):
    """Display GPIO bank 1 atom information"""
    if len(data) < 20:
        print(f"    GPIO Bank 1: Invalid data length ({len(data)} bytes, expected 20)")
        return
    
    bank_drive = data[0]
    # data[1] is reserved
    
    drive = bank_drive & 0x0F
    slew = (bank_drive >> 4) & 0x03
    hysteresis = (bank_drive >> 6) & 0x03
    
    print(f"    GPIO Bank 1 Configuration:")
    print(f"      Drive strength: {drive} ({'default' if drive == 0 else f'{drive*2}mA'})")
    print(f"      Slew rate: {slew} ({'default' if slew == 0 else 'limiting' if slew == 1 else 'no limiting' if slew == 2 else 'reserved'})")
    print(f"      Hysteresis: {hysteresis} ({'default' if hysteresis == 0 else 'disabled' if hysteresis == 1 else 'enabled' if hysteresis == 2 else 'reserved'})")
    
    print(f"      GPIO Pin Configuration (28-45):")
    for i in range(18):  # GPIO 28-45
        gpio_byte = data[2 + i]
        func_sel = gpio_byte & 0x07
        pulltype = (gpio_byte >> 5) & 0x03
        is_used = (gpio_byte >> 7) & 0x01
        
        if is_used:
            pull_str = ['default', 'pullup', 'pulldown', 'no pull'][pulltype]
            print(f"        GPIO {28 + i}: Function {func_sel}, Pull: {pull_str}")


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
    info_parser = subparsers.add_parser('info', help='Display HAT vendor information from EEPROM')
    info_parser.add_argument('--debug', action='store_true', help='Enable debug output for atom parsing')
    info_parser.add_argument('--all', action='store_true', help='Parse and display all atoms, not just vendor info')
    
    # Short info command  
    shortinfo_parser = subparsers.add_parser('shortinfo', help='Display HAT info in short format: vendor:product:uuid')
    shortinfo_parser.add_argument('--debug', action='store_true', help='Enable debug output for atom parsing')
    
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
        # Use vendor_only=True for efficiency unless --all is specified
        vendor_only = not args.all
        hat_info = eeprom.read_and_parse_hat(size=None, debug=args.debug, vendor_only=vendor_only)
        
        if hat_info is None:
            print("Error: Failed to read EEPROM data")
            return 1
            
        if not hat_info['valid']:
            print(f"Error: {hat_info.get('error', 'Invalid HAT EEPROM data')}")
            return 1
        
        if args.all:
            # Display all information including header and all atoms
            print("HAT EEPROM Information:")
            print("=" * 50)
            
            # Display header information
            if hat_info.get('header'):
                h = hat_info['header']
                print(f"\nHeader:")
                signature = h.get('signature', 0)
                if isinstance(signature, int):
                    print(f"  Signature: 0x{signature:08X}")
                else:
                    print(f"  Signature: {signature}")
                print(f"  Version: {h.get('version', 'N/A')}")
                print(f"  Number of atoms: {h.get('num_atoms', 'N/A')}")
                print(f"  Total length: {h.get('eep_len', 'N/A')} bytes")
            
            # Display all atoms
            if hat_info.get('atoms'):
                print(f"\nAtoms ({len(hat_info['atoms'])}):")
                for i, atom in enumerate(hat_info['atoms']):
                    print(f"\n  Atom {i+1}:")
                    print(f"    Type: 0x{atom['type']:04X} ({_get_atom_type_name(atom['type'])})")
                    print(f"    Sequence: {atom['sequence']}")
                    print(f"    Data length: {atom['data_length']} bytes")
                    print(f"    Total length: {atom['total_length']} bytes")
                    print(f"    CRC: 0x{atom['crc']:04X}")
                    
                    # Display parsed content for known atom types
                    if atom['type'] == 0x0001 and 'parsed' in atom:
                        _display_vendor_atom(atom['parsed'])
                    elif atom['type'] == 0x0002:
                        _display_gpio_bank0_atom(atom['data'])
                    elif atom['type'] == 0x0003:
                        _display_device_tree_atom(atom['data'])
                    elif atom['type'] == 0x0004:
                        _display_custom_data_atom(atom['data'])
                    elif atom['type'] == 0x0005:
                        _display_gpio_bank1_atom(atom['data'])
                    else:
                        # Display raw data for unknown atom types
                        if len(atom['data']) > 0:
                            print(f"    Raw data: {atom['data'][:32].hex()}")
                            if len(atom['data']) > 32:
                                print(f"    ... ({len(atom['data'])} bytes total)")
            else:
                print("\nNo atoms found")
        else:
            # Display only vendor information (original behavior)
            if hat_info['vendor_info']:
                vi = hat_info['vendor_info']
                print("HAT Vendor Information:")
                print(f"  UUID: {vi.get('uuid', 'N/A')}")
                
                pid = vi.get('pid')
                if pid is not None:
                    print(f"  Product ID: 0x{pid:04X}")
                else:
                    print("  Product ID: N/A")
                
                pver = vi.get('pver')
                if pver is not None:
                    print(f"  Product Version: 0x{pver:04X}")
                else:
                    print("  Product Version: N/A")
                    
                print(f"  Vendor: {vi.get('vendor', 'N/A')}")
                print(f"  Product: {vi.get('product', 'N/A')}")
            else:
                print("No vendor information found in HAT EEPROM")
            
    elif args.command == 'shortinfo':
        # Use the library's short_info method for consistency
        result = eeprom.format_short_info(separator=':', debug=args.debug)
        print(result)
    
    return 0


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""
HAT EEPROM Command Line Tool

Command-line interface for the hateeprom library.
"""

import argparse
import sys

from hateeprom import HatEEPROM


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

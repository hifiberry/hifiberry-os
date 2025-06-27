#!/usr/bin/env python3
"""
Example script demonstrating how to use the hateeprom library
"""

from hateeprom import HatEEPROM

def main():
    # Initialize HAT EEPROM interface
    # Default: I2C address 0x50, SDA on GPIO0, SCL on GPIO1
    eeprom = HatEEPROM()
    
    print("HAT EEPROM Library Example")
    print("=" * 30)
    
    # Check if EEPROM is available
    print("1. Checking EEPROM availability...")
    if eeprom.is_available():
        print("   ✓ HAT EEPROM detected and responding")
    else:
        print("   ✗ No HAT EEPROM detected")
        return
    
    # Read and parse HAT information
    print("\n2. Reading HAT information...")
    hat_info = eeprom.read_and_parse_hat()
    
    if not hat_info['valid']:
        print(f"   ✗ Error: {hat_info.get('error', 'Invalid HAT EEPROM data')}")
        return
    
    print(f"   ✓ HAT Signature: {hat_info['signature']}")
    print(f"   ✓ HAT Version: {hat_info['version']}")
    print(f"   ✓ Atoms found: {len(hat_info['atoms'])}")
    
    # Display vendor information
    if hat_info['vendor_info']:
        vi = hat_info['vendor_info']
        print("\n3. Vendor Information:")
        print(f"   UUID: {vi.get('uuid', 'N/A')}")
        print(f"   Product ID: 0x{vi.get('pid', 0):04X}")
        print(f"   Product Version: 0x{vi.get('pver', 0):04X}")
        print(f"   Vendor: {vi.get('vendor', 'N/A')}")
        print(f"   Product: {vi.get('product', 'N/A')}")
    
    # Read raw data example
    print("\n4. Reading raw data (first 64 bytes)...")
    raw_data = eeprom.read_data(0, 64)
    if raw_data:
        print("   ✓ Raw EEPROM data (hex):")
        for i in range(0, len(raw_data), 16):
            hex_bytes = ' '.join(f'{b:02X}' for b in raw_data[i:i+16])
            ascii_chars = ''.join(chr(b) if 32 <= b <= 126 else '.' for b in raw_data[i:i+16])
            print(f'   {i:04X}: {hex_bytes:<48} {ascii_chars}')
    
    print("\nExample completed successfully!")

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\nOperation cancelled by user")
    except Exception as e:
        print(f"Error: {e}")

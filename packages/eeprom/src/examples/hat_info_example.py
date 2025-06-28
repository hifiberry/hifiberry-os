#!/usr/bin/env python3
"""
Example usage of hateeprom library short_info() method
This demonstrates how other programs can integrate HAT EEPROM reading
"""

from hateeprom import HatEEPROM

def main():
    print("HAT EEPROM Library Usage Example")
    print("=" * 40)
    
    # Initialize HAT EEPROM interface
    hat = HatEEPROM()
    
    # Example 1: Get structured information
    print("\n1. Getting structured HAT information:")
    info = hat.short_info(debug=False)
    
    if info['success']:
        print(f"   Vendor: {info['vendor']}")
        print(f"   Product: {info['product']}")
        print(f"   UUID: {info['uuid']}")
        if info['pid'] is not None:
            print(f"   Product ID: 0x{info['pid']:04X}")
        if info['pver'] is not None:
            print(f"   Product Version: 0x{info['pver']:04X}")
    else:
        print(f"   Error: {info['error']}")
    
    # Example 2: Get formatted string (default colon separator)
    print("\n2. Getting formatted string (colon-separated):")
    formatted = hat.format_short_info()
    print(f"   {formatted}")
    
    # Example 3: Get formatted string with custom separator
    print("\n3. Getting formatted string (pipe-separated):")
    formatted_pipe = hat.format_short_info(separator='|')
    print(f"   {formatted_pipe}")
    
    # Example 4: Check if HAT is available first
    print("\n4. Checking HAT availability:")
    if hat.is_available():
        print("   HAT EEPROM is available")
        # You can safely call short_info() here
    else:
        print("   HAT EEPROM is not available or not responding")
    
    # Example 5: Integration in a larger program
    print("\n5. Example integration pattern:")
    try:
        info = hat.short_info()
        if info['success']:
            # Use the information in your program
            hat_description = f"{info['vendor']} {info['product']}"
            print(f"   Detected HAT: {hat_description}")
            print(f"   UUID: {info['uuid']}")
            
            # You could store this in a config file, database, etc.
            config = {
                'hat_detected': True,
                'hat_vendor': info['vendor'],
                'hat_product': info['product'],
                'hat_uuid': info['uuid']
            }
            print(f"   Config data: {config}")
        else:
            print(f"   No HAT detected: {info['error']}")
            config = {'hat_detected': False}
            
    except Exception as e:
        print(f"   Exception: {e}")

if __name__ == '__main__':
    main()

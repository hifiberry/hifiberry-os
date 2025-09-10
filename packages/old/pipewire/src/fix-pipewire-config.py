#!/usr/bin/env python3
"""
Fix PipeWire configuration for headless systems by removing D-Bus dependent modules.

This script removes problematic modules that cause errors in headless environments:
- libpipewire-module-portal (requires session bus)
- libpipewire-module-jackdbus-detect (requires session bus)
- libpipewire-module-x11-bell (requires X11)

The script creates a system-wide override configuration in /etc/pipewire/pipewire.conf.d/
"""

import os
import json
import sys
from pathlib import Path

def create_pipewire_override():
    """Create a PipeWire configuration override to disable problematic modules."""
    
    # Configuration override to disable problematic modules
    override_config = {
        "context.properties": {
            "module.portal": False,
            "module.jackdbus-detect": False,
            "module.x11.bell": False
        }
    }
    
    # Create the override directory
    override_dir = Path("/etc/pipewire/pipewire.conf.d")
    override_dir.mkdir(parents=True, exist_ok=True)
    
    # Write the override file
    override_file = override_dir / "99-hifiberry-headless.conf"
    
    try:
        with open(override_file, 'w') as f:
            f.write("# HiFiBerry PipeWire configuration override for headless systems\n")
            f.write("# This file disables modules that require D-Bus session or X11\n")
            f.write("# Generated automatically by hifiberry-pipewire package\n\n")
            f.write("context.properties = {\n")
            f.write("    # Disable portal module (requires session bus)\n")
            f.write("    module.portal = false\n")
            f.write("    \n")
            f.write("    # Disable JACK D-Bus detection (requires session bus)\n")
            f.write("    module.jackdbus-detect = false\n")
            f.write("    \n")
            f.write("    # Disable X11 bell (requires X11 display)\n")
            f.write("    module.x11.bell = false\n")
            f.write("}\n")
        
        print(f"Created PipeWire override configuration: {override_file}")
        
        # Set appropriate permissions
        os.chmod(override_file, 0o644)
        
        return True
        
    except Exception as e:
        print(f"Error creating PipeWire override configuration: {e}", file=sys.stderr)
        return False

def main():
    """Main function to fix PipeWire configuration."""
    print("Fixing PipeWire configuration for headless system...")
    
    if os.geteuid() != 0:
        print("Warning: Not running as root. Configuration may not be writable.", file=sys.stderr)
    
    success = create_pipewire_override()
    
    if success:
        print("PipeWire configuration fixed successfully.")
        print("Restart PipeWire services to apply changes:")
        print("  systemctl restart pipewire pipewire-pulse wireplumber")
        return 0
    else:
        print("Failed to fix PipeWire configuration.", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())

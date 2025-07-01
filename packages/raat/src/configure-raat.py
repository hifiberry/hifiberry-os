#!/usr/bin/env python3
"""
Configure RAAT server for HiFiBerry devices
This script generates the RAAT configuration file based on detected hardware
"""

import os
import sys
import json
import subprocess
import argparse
from pathlib import Path

# Import configurator modules
try:
    from configurator.soundcard import Soundcard
except ImportError as e:
    print(f"Error importing configurator modules: {e}")
    print("Make sure the configurator package is installed")
    sys.exit(1)

def get_uuid():
    """Read UUID from /etc/uuid"""
    try:
        with open('/etc/uuid', 'r') as f:
            return f.read().strip()
    except FileNotFoundError:
        print("Error: /etc/uuid not found")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading UUID: {e}")
        sys.exit(1)

def get_version():
    """Get version from placeholder (will be replaced during build)"""
    return "###MYVERSION###"

def detect_soundcard():
    """Detect soundcard using configurator module"""
    try:
        # Get soundcard information using configurator
        soundcard = Soundcard()
        
        if soundcard and soundcard.name != 'Unknown':
            card_name = soundcard.name
            # Map card names to RAAT-friendly names
            if 'digi' in card_name.lower():
                return 'Digi+'
            else:
                return 'DAC+'
        else:
            # Fallback to aplay detection
            result = subprocess.run(['aplay', '-l'], capture_output=True, text=True)
            if 'hifiberry' in result.stdout.lower():
                if 'digi' in result.stdout.lower():
                    return 'Digi+'
                else:
                    return 'DAC+'
            return 'DAC+'
            
    except PermissionError as e:
        print(f"Warning: GPIO permission error, using fallback detection: {e}")
        # Fallback to aplay detection when GPIO access is denied
        try:
            result = subprocess.run(['aplay', '-l'], capture_output=True, text=True)
            if 'hifiberry' in result.stdout.lower():
                if 'digi' in result.stdout.lower():
                    return 'Digi+'
                else:
                    return 'DAC+'
            return 'DAC+'
        except Exception:
            return 'DAC+'
    except Exception as e:
        print(f"Warning: Error detecting soundcard: {e}")
        # Final fallback to aplay detection
        try:
            result = subprocess.run(['aplay', '-l'], capture_output=True, text=True)
            if 'hifiberry' in result.stdout.lower():
                if 'digi' in result.stdout.lower():
                    return 'Digi+'
                else:
                    return 'DAC+'
            return 'DAC+'
        except Exception:
            return 'DAC+'

def get_driver_name():
    """Get the driver name from aplay output"""
    try:
        result = subprocess.run(['aplay', '-l'], capture_output=True, text=True)
        lines = result.stdout.split('\n')
        for line in lines:
            if '[snd_rpi' in line:
                # Extract driver name between [ and ]
                start = line.find('[snd_rpi')
                if start != -1:
                    end = line.find(']', start)
                    if end != -1:
                        return line[start+1:end]
        return 'unknown'
    except Exception:
        return 'unknown'

def get_volume_control():
    """Get volume control configuration using configurator"""
    try:
        # Use configurator commands to get volume control info
        mixer_result = subprocess.run(['config-soundcard', '--volume-control-softvol'], 
                                    capture_output=True, text=True)
        hw_result = subprocess.run(['config-soundcard', '--hw'], 
                                 capture_output=True, text=True)
        
        if mixer_result.returncode == 0 and hw_result.returncode == 0:
            mixer = mixer_result.stdout.strip()
            mixer_hw = hw_result.stdout.strip()
            
            return {
                "type": "alsa",
                "optional": "false", 
                "device": f"hw:{mixer_hw}",
                "index": 0,
                "name": mixer,
                "mode": "number"
            }
        else:
            # Fallback to software volume
            return {"type": "software"}
            
    except PermissionError as e:
        print(f"Warning: GPIO permission error in volume control detection, using software volume: {e}")
        return {"type": "software"}
    except Exception as e:
        print(f"Warning: Error getting volume control: {e}")
        return {"type": "software"}

def generate_supported_formats():
    """Generate supported audio formats"""
    sample_rates = [44100, 48000, 88200, 96000, 176400, 192000]
    bit_depths = [16, 24, 32]
    channels = 2
    
    formats = []
    for rate in sample_rates:
        for bits in bit_depths:
            formats.append({
                "sample_type": "pcm",
                "sample_rate": rate,
                "bits_per_sample": bits,
                "channels": channels
            })
    
    return formats

def main():
    """Main configuration function"""
    parser = argparse.ArgumentParser(
        description="Configure RAAT server for HiFiBerry devices",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        '-o', '--output',
        default='/var/lib/raat/hifiberry.conf',
        help='Output configuration file path (default: /var/lib/raat/hifiberry.conf)'
    )
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Enable verbose output'
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        print("Configuring RAAT server...")
    
    # Get system information
    uuid = get_uuid()
    card = detect_soundcard()
    driver = get_driver_name()
    version = get_version()
    
    if args.verbose:
        print(f"Configuring RAAT server for UUID {uuid} on {card} ({driver})")
    
    # Get volume control configuration
    volume_config = get_volume_control()
    
    # Generate RAAT configuration
    config = {
        "_comment": "This file is generated by HiFiBerry. Do not edit manually.",
        "vendor": "HiFiBerry",
        "model": card,
        "unique_id": uuid,
        "output": {
            "type": "alsa",
            "device": "default",
            "max_pcm_rate": 192000,
            "signal_path": [
                {
                    "quality": "lossless",
                    "type": "output", 
                    "method": "analog"
                }
            ],
            "supported_formats": generate_supported_formats()
        },
        "volume": volume_config,
        "version": version,
        "transport": {
            "type": "hifiberry"
        }
    }
    
    # Ensure output directory exists
    config_file = Path(args.output)
    config_file.parent.mkdir(parents=True, exist_ok=True)
    
    # Write configuration file
    try:
        with open(config_file, 'w') as f:
            json.dump(config, f, indent=4)
        if args.verbose:
            print(f"RAAT configuration written to {config_file}")
    except Exception as e:
        print(f"Error writing configuration file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

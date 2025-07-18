#!/usr/bin/env python3
"""
Configure MPD by updating mixer settings and creating runtime configuration
This script reads /etc/mpd.conf and generates /var/lib/mpd/mpd.conf with updated mixer settings
"""

import os
import sys
import shutil
import subprocess
import re
from pathlib import Path

def get_hw_mixer_info():
    """Get hardware mixer information using config-soundcard"""
    try:
        # Get volume control softvol setting
        mixer_result = subprocess.run(['config-soundcard', '--no-eeprom', '--volume-control-softvol'], 
                                    capture_output=True, text=True)
        hw_result = subprocess.run(['config-soundcard', '--no-eeprom', '--hw'], 
                                 capture_output=True, text=True)
        
        if mixer_result.returncode == 0 and hw_result.returncode == 0:
            mixer = mixer_result.stdout.strip()
            mixer_hw = hw_result.stdout.strip()
            
            return {
                "mixer_type": "hardware",
                "mixer_device": f"hw:{mixer_hw}",
                "mixer_control": mixer,
                "mixer_index": 0
            }
        else:
            # Fallback to software volume
            return {
                "mixer_type": "software"
            }
            
    except Exception as e:
        print(f"Warning: Error getting mixer info: {e}")
        return {
            "mixer_type": "software"
        }

def get_samba_mounted_dirs():
    """Get list of Samba mounted directories"""
    try:
        result = subprocess.run(['config-sambamount', '--list-mounted-dirs'], 
                               capture_output=True, text=True)
        
        if result.returncode == 0:
            # Split output by lines and filter out empty lines
            dirs = [line.strip() for line in result.stdout.strip().split('\n') if line.strip()]
            return dirs
        else:
            print(f"Warning: config-sambamount failed: {result.stderr}")
            return []
            
    except Exception as e:
        print(f"Warning: Error getting Samba mounted directories: {e}")
        return []

def parse_music_directory(config_file):
    """Parse music_directory setting from MPD config file"""
    try:
        with open(config_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line.startswith('music_directory') and not line.startswith('#'):
                    # Extract the directory path from the line
                    # Format: music_directory "/var/lib/mpd/music"
                    match = re.search(r'music_directory\s+["\']([^"\']+)["\']', line)
                    if match:
                        return match.group(1)
        
        # Default fallback
        return "/var/lib/mpd/music"
        
    except Exception as e:
        print(f"Warning: Error parsing music directory: {e}")
        return "/var/lib/mpd/music"

def manage_music_symlinks(music_dir, samba_dirs):
    """Manage symlinks in the music directory"""
    music_path = Path(music_dir)
    
    # Ensure music directory exists
    music_path.mkdir(parents=True, exist_ok=True)
    
    # Remove broken symlinks
    for item in music_path.iterdir():
        if item.is_symlink() and not item.exists():
            print(f"Removing broken symlink: {item}")
            try:
                item.unlink()
            except Exception as e:
                print(f"Warning: Could not remove broken symlink {item}: {e}")
    
    # Create symlinks for Samba mounted directories
    for samba_dir in samba_dirs:
        samba_path = Path(samba_dir)
        if not samba_path.exists():
            print(f"Warning: Samba directory does not exist: {samba_dir}")
            continue
        
        # Create symlink name based on the directory name
        symlink_name = samba_path.name
        symlink_path = music_path / symlink_name
        
        # Skip if symlink already exists and points to the correct location
        if symlink_path.is_symlink() and symlink_path.resolve() == samba_path.resolve():
            print(f"Symlink already exists: {symlink_path} -> {samba_dir}")
            continue
        
        # Remove existing file/symlink if it exists
        if symlink_path.exists() or symlink_path.is_symlink():
            try:
                if symlink_path.is_dir() and not symlink_path.is_symlink():
                    shutil.rmtree(symlink_path)
                else:
                    symlink_path.unlink()
                print(f"Removed existing item: {symlink_path}")
            except Exception as e:
                print(f"Warning: Could not remove existing item {symlink_path}: {e}")
                continue
        
        # Create the symlink
        try:
            symlink_path.symlink_to(samba_path)
            print(f"Created symlink: {symlink_path} -> {samba_dir}")
        except Exception as e:
            print(f"Warning: Could not create symlink {symlink_path}: {e}")

def update_mpd_config(input_file, output_file, mixer_info):
    """Update MPD configuration with new mixer settings"""
    
    # Header comment
    header = f"""# MPD Configuration File
# DO NOT EDIT THIS FILE MANUALLY!
# This file is automatically generated by configure-mpd
# Source configuration: {input_file}
# To make changes, edit {input_file} and restart the mpd service

"""
    
    try:
        with open(input_file, 'r') as f:
            config_lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: Source configuration file not found: {input_file}")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading configuration file: {e}")
        sys.exit(1)
    
    # Process configuration lines
    output_lines = []
    in_audio_output = False
    audio_output_depth = 0
    mixer_lines_added = False
    
    for line in config_lines:
        stripped = line.strip()
        
        # Track audio_output block
        if stripped.startswith('audio_output {'):
            in_audio_output = True
            audio_output_depth = 1
            output_lines.append(line)
            continue
        elif in_audio_output:
            if '{' in line:
                audio_output_depth += line.count('{')
            if '}' in line:
                audio_output_depth -= line.count('}')
                if audio_output_depth == 0:
                    # End of audio_output block, add mixer settings if not already added
                    if not mixer_lines_added:
                        if mixer_info["mixer_type"] == "hardware":
                            output_lines.append(f'\tmixer_type\t\t"hardware"\n')
                            output_lines.append(f'\tmixer_device\t\t"{mixer_info["mixer_device"]}"\n')
                            output_lines.append(f'\tmixer_control\t\t"{mixer_info["mixer_control"]}"\n')
                            output_lines.append(f'\tmixer_index\t\t"{mixer_info["mixer_index"]}"\n')
                        else:
                            output_lines.append(f'\tmixer_type\t\t"software"\n')
                        mixer_lines_added = True
                    in_audio_output = False
                    output_lines.append(line)
                    continue
        
        # Skip existing mixer settings in audio_output blocks
        if in_audio_output and (stripped.startswith('mixer_type') or 
                               stripped.startswith('mixer_device') or 
                               stripped.startswith('mixer_control') or 
                               stripped.startswith('mixer_index')):
            continue
        
        output_lines.append(line)
    
    # Write the updated configuration
    try:
        # Ensure output directory exists
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_file, 'w') as f:
            f.write(header)
            f.writelines(output_lines)
        
        # Set proper ownership and permissions
        try:
            shutil.chown(output_file, user='mpd', group='audio')
            os.chmod(output_file, 0o644)
        except PermissionError:
            print("Warning: Could not set ownership/permissions (may require root)")
            
        print(f"MPD configuration updated: {output_file}")
        
    except Exception as e:
        print(f"Error writing configuration file: {e}")
        sys.exit(1)

def main():
    """Main configuration function"""
    input_config = "/etc/mpd.conf"
    output_config = "/var/lib/mpd/mpd.conf"
    
    # Check if source configuration exists
    if not os.path.exists(input_config):
        print(f"Error: Source configuration file not found: {input_config}")
        sys.exit(1)
    
    print("Configuring MPD...")
    
    # Get mixer information
    mixer_info = get_hw_mixer_info()
    print(f"Mixer configuration: {mixer_info['mixer_type']}")
    if mixer_info["mixer_type"] == "hardware":
        print(f"Hardware mixer: {mixer_info['mixer_control']} on {mixer_info['mixer_device']}")
    
    # Update configuration
    update_mpd_config(input_config, output_config, mixer_info)
    
    # Handle Samba mount symlinks
    print("Managing music directory symlinks...")
    music_dir = parse_music_directory(input_config)
    samba_dirs = get_samba_mounted_dirs()
    
    print(f"Music directory: {music_dir}")
    if samba_dirs:
        print(f"Found {len(samba_dirs)} Samba mounted directories:")
        for samba_dir in samba_dirs:
            print(f"  {samba_dir}")
    else:
        print("No Samba mounted directories found")
    
    manage_music_symlinks(music_dir, samba_dirs)
    
    print("MPD configuration completed successfully")

if __name__ == "__main__":
    main()

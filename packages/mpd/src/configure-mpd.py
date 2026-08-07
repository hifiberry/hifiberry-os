#!/usr/bin/env python3
"""
Configure MPD for per-user service.
Ensures ~/etc/mpd.conf exists (from /usr/share/mpd/mpd.conf) and updates
its audio_output mixer settings based on detected hardware.
"""

import os
import sys
import shutil
import subprocess
import re
from pathlib import Path

USER_ETC = Path.home() / "etc"
USER_CONFIG = USER_ETC / "mpd.conf"
DEFAULT_CONFIG_SRC = Path("/usr/share/mpd/mpd.conf")

def get_pretty_hostname():
    """Get the pretty hostname, falling back to the hostname, then "HiFiBerry".

    Same order start-shairport.sh and start-librespot.sh use for the name they
    announce, so all three players show up under one name.
    """
    try:
        result = subprocess.run(['hostnamectl', 'hostname', '--pretty'],
                                capture_output=True, text=True)
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except Exception as e:
        print(f"Warning: Could not read pretty hostname: {e}")

    try:
        result = subprocess.run(['hostname'], capture_output=True, text=True)
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except Exception as e:
        print(f"Warning: Could not read hostname: {e}")

    return "HiFiBerry"


def update_zeroconf_name(config_path, name):
    """Set zeroconf_name in the MPD config, leaving every other line untouched."""
    # MPD's config tokenizer treats \ as an escape inside a quoted string, so a
    # name containing " or \ has to be escaped or the value is truncated/broken.
    escaped = name.replace('\\', '\\\\').replace('"', '\\"')
    try:
        with open(config_path, 'r') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Warning: Could not read {config_path} to set zeroconf_name: {e}")
        return

    out = []
    replaced = False
    for line in lines:
        if line.strip().split()[:1] == ['zeroconf_name']:
            if not replaced:
                out.append(f'zeroconf_name\t\t"{escaped}"\n')
                replaced = True
            continue
        out.append(line)

    if not replaced:
        # No zeroconf_name in the config (e.g. a hand-edited one): add it.
        if out and not out[-1].endswith('\n'):
            out[-1] += '\n'
        out.append(f'zeroconf_name\t\t"{escaped}"\n')

    try:
        with open(config_path, 'w') as f:
            f.writelines(out)
        print(f"Zeroconf name set to: {name}")
    except Exception as e:
        print(f"Warning: Could not write zeroconf_name to {config_path}: {e}")


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

def parse_db_file(config_file):
    """Parse db_file setting from MPD config file"""
    try:
        with open(config_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line.startswith('db_file') and not line.startswith('#'):
                    match = re.search(r'db_file\s+["\']([^"\']+)["\']', line)
                    if match:
                        return match.group(1)
        # Default fallback
        return "/var/lib/mpd/database"
    except Exception as e:
        print(f"Warning: Error parsing db_file: {e}")
        return "/var/lib/mpd/database"

def ensure_and_chown_db_file(db_path_str):
    """Ensure the DB file exists (if possible) and chown it to the current user."""
    db_path = Path(db_path_str)
    uid = os.getuid()
    gid = os.getgid()
    try:
        # Try to create parent dir if missing (may fail without permissions)
        db_path.parent.mkdir(parents=True, exist_ok=True)
    except Exception:
        pass
    # Try to create the file if it doesn't exist
    if not db_path.exists():
        try:
            db_path.touch(exist_ok=True)
        except Exception:
            # Can't create; will still try chown in case it appears later
            pass
    # Try to chown
    try:
        os.chown(str(db_path), uid, gid)
        # Make it user-writable
        os.chmod(str(db_path), 0o664)
        print(f"Adjusted ownership of MPD database: {db_path} -> uid={uid}, gid={gid}")
    except PermissionError:
        print(f"Warning: No permission to change ownership of {db_path}")
    except FileNotFoundError:
        print(f"Warning: Database file does not exist and could not be created: {db_path}")
    except Exception as e:
        print(f"Warning: Could not adjust database ownership: {e}")

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

def update_mpd_config_in_place(config_path, mixer_info):
    """Update MPD configuration with mixer settings in-place for user file."""
    try:
        with open(config_path, 'r') as f:
            config_lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: Configuration file not found: {config_path}")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading configuration file: {e}")
        sys.exit(1)

    output_lines = []
    in_audio_output = False
    audio_output_depth = 0
    mixer_lines_added = False

    for line in config_lines:
        stripped = line.strip()

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

        if in_audio_output and (stripped.startswith('mixer_type') or
                                 stripped.startswith('mixer_device') or
                                 stripped.startswith('mixer_control') or
                                 stripped.startswith('mixer_index')):
            continue

        output_lines.append(line)

    try:
        Path(config_path).parent.mkdir(parents=True, exist_ok=True)
        try:
            shutil.copy2(config_path, str(config_path) + ".bak")
        except Exception:
            pass
        with open(config_path, 'w') as f:
            f.writelines(output_lines)
        print(f"MPD configuration updated: {config_path}")
    except Exception as e:
        print(f"Error writing configuration file: {e}")
        sys.exit(1)

def main():
    """Main configuration function for user-service MPD."""
    # Ensure user config exists and is not empty
    if not USER_CONFIG.exists() or USER_CONFIG.stat().st_size == 0:
        USER_ETC.mkdir(parents=True, exist_ok=True)
        if DEFAULT_CONFIG_SRC.exists():
            shutil.copy2(DEFAULT_CONFIG_SRC, USER_CONFIG)
            print(f"Installed default MPD configuration to {USER_CONFIG}")
        else:
            print(f"Error: Default MPD configuration not found at {DEFAULT_CONFIG_SRC}")
            sys.exit(1)

    print("Configuring MPD (user)...")

    mixer_info = get_hw_mixer_info()
    print(f"Mixer configuration: {mixer_info['mixer_type']}")
    if mixer_info["mixer_type"] == "hardware":
        print(f"Hardware mixer: {mixer_info['mixer_control']} on {mixer_info['mixer_device']}")

    update_mpd_config_in_place(USER_CONFIG, mixer_info)

    # Announce the same name as the other players (shairport, librespot), which
    # both read the pretty hostname at startup. MPD takes its Zeroconf name from
    # the config file only, so it has to be written here on every start.
    update_zeroconf_name(USER_CONFIG, get_pretty_hostname())

    print("Managing music directory symlinks...")
    music_dir = parse_music_directory(USER_CONFIG)
    samba_dirs = get_samba_mounted_dirs()

    print(f"Music directory: {music_dir}")
    if samba_dirs:
        print(f"Found {len(samba_dirs)} Samba mounted directories:")
        for samba_dir in samba_dirs:
            print(f"  {samba_dir}")
    else:
        print("No Samba mounted directories found")

    manage_music_symlinks(music_dir, samba_dirs)

    # Ensure the database file is owned by the current user
    db_file = parse_db_file(USER_CONFIG)
    ensure_and_chown_db_file(db_file)

    print("MPD configuration (user) completed successfully")

if __name__ == "__main__":
    main()

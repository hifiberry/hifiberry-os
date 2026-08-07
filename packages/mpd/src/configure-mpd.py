#!/usr/bin/env python3
"""
Configure MPD for per-user service.
Ensures ~/etc/mpd.conf exists (from /usr/share/mpd/mpd.conf) and updates
its audio_output mixer settings based on detected hardware.
"""

import os
import socket
import sys
import shutil
import subprocess
import re
from pathlib import Path

# Import configurator modules. Unlike configure-raat, a missing configurator is
# not fatal here: it only costs us the announced name, and MPD should still
# start, so we fall back instead of exiting.
try:
    from configurator.hostname_utils import get_hostnames_with_fallback
except ImportError as e:
    print(f"Warning: Could not import configurator hostname utils: {e}")
    get_hostnames_with_fallback = None

USER_ETC = Path.home() / "etc"
USER_CONFIG = USER_ETC / "mpd.conf"
DEFAULT_CONFIG_SRC = Path("/usr/share/mpd/mpd.conf")

# Avahi's service-name label is capped at 63 bytes. The hostname API accepts up
# to 64 characters, so a long name -- or a shorter one with multi-byte
# characters -- would make registration fail and MPD vanish from Zeroconf.
ZEROCONF_NAME_MAX_BYTES = 63

# A device with no pretty hostname set typically reports the default system
# hostname, which isn't a name anyone wants announced on the network.
UNSET_HOSTNAMES = ("", "localhost")

DEFAULT_NAME = "HiFiBerry"


def get_pretty_hostname():
    """Get the pretty hostname, falling back to the hostname, then "HiFiBerry".

    The hostnamectl calls come from configurator.hostname_utils (already a
    dependency), which bounds them with a timeout -- this runs synchronously
    before `exec mpd`, so an unbounded D-Bus round-trip to a wedged
    systemd-hostnamed would hang mpd.service in "activating" forever.

    The helper stops one step short of what the players need, though: it falls
    pretty -> hostname and then returns None, with no "HiFiBerry" default, and
    it treats a literal "localhost" as a real name. Both are applied here so
    MPD announces what start-shairport.sh, start-librespot.sh and
    start-squeezelite announce, rather than "localhost" or nothing.
    """
    hostname = pretty_hostname = None
    if get_hostnames_with_fallback is not None:
        try:
            hostname, pretty_hostname = get_hostnames_with_fallback()
        except Exception as e:
            print(f"Warning: Could not read hostnames from configurator: {e}")

    for name in (pretty_hostname, hostname):
        if name and name.strip().lower() not in UNSET_HOSTNAMES:
            return name.strip()

    # Last resort if the configurator import or both hostnamectl calls failed.
    # socket.gethostname() can't hang and needs no error handling.
    name = socket.gethostname().strip()
    if name and name.lower() not in UNSET_HOSTNAMES:
        return name

    return DEFAULT_NAME


def truncate_to_bytes(name, limit=ZEROCONF_NAME_MAX_BYTES):
    """Truncate a name to `limit` UTF-8 bytes without splitting a character."""
    encoded = name.encode('utf-8')
    if len(encoded) <= limit:
        return name
    truncated = encoded[:limit].decode('utf-8', errors='ignore')
    print(f"Warning: Zeroconf name too long for mDNS, truncated to: {truncated}")
    return truncated


def format_zeroconf_name(name):
    """Render the canonical zeroconf_name line for the given name."""
    # MPD's config tokenizer treats \ as an escape inside a quoted string, so a
    # name containing " or \ has to be escaped or the value is truncated/broken.
    escaped = truncate_to_bytes(name).replace('\\', '\\\\').replace('"', '\\"')
    return f'zeroconf_name\t\t"{escaped}"\n'


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

def update_mpd_config_in_place(config_path, mixer_info, zeroconf_name=None):
    """Update MPD configuration in-place for user file.

    Rewrites the audio_output mixer settings, and -- when zeroconf_name is given
    -- the top-level zeroconf_name. Both are managed keys: existing lines are
    dropped and the canonical form re-emitted.
    """
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
    zeroconf_line_added = False

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

        # zeroconf_name is a top-level key; only drop it outside a block, so a
        # stray copy nested in audio_output is left alone rather than becoming
        # the line we re-emit (MPD rejects it there as an unknown parameter).
        if zeroconf_name is not None and not in_audio_output and \
                stripped.split()[:1] == ['zeroconf_name']:
            if not zeroconf_line_added:
                output_lines.append(format_zeroconf_name(zeroconf_name))
                zeroconf_line_added = True
            continue

        output_lines.append(line)

    if zeroconf_name is not None and not zeroconf_line_added:
        # No top-level zeroconf_name (e.g. a hand-edited config): append it.
        if output_lines and not output_lines[-1].endswith('\n'):
            output_lines[-1] += '\n'
        output_lines.append(format_zeroconf_name(zeroconf_name))

    try:
        Path(config_path).parent.mkdir(parents=True, exist_ok=True)
        try:
            shutil.copy2(config_path, str(config_path) + ".bak")
        except Exception:
            pass
        # Write via a temp file and rename. A truncating in-place write that dies
        # partway (full SD card, killed mid-restart) would leave a config cut off
        # mid-line that start-mpd.sh then execs mpd on -- and the self-heal in
        # main() only catches a zero-length file, so it would survive reboots.
        tmp_path = str(config_path) + ".tmp"
        with open(tmp_path, 'w') as f:
            f.writelines(output_lines)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp_path, config_path)
        print(f"MPD configuration updated: {config_path}")
    except Exception as e:
        print(f"Error writing configuration file: {e}")
        try:
            os.unlink(str(config_path) + ".tmp")
        except Exception:
            pass
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

    # Announce the same name as the other players (shairport, librespot,
    # squeezelite), which all read the pretty hostname at startup. MPD takes its
    # Zeroconf name from the config file only, so it has to be written here on
    # every start -- folded into the mixer pass so the config is read and
    # rewritten once.
    zeroconf_name = get_pretty_hostname()
    print(f"Zeroconf name: {zeroconf_name}")

    update_mpd_config_in_place(USER_CONFIG, mixer_info, zeroconf_name)

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

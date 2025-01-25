#!/usr/bin/env python3

import hashlib
import os
import argparse

# Define the simple ALSA configuration template as a constant
SIMPLE_CONFIG_TEMPLATE = """pcm.!default {{
    type hw
    card {hw}
    device 0
    channels {channels}
}}

ctl.!default {{
    type hw
    card {hw}
}}
"""

class ALSAConfig:
    def __init__(self, filename='/etc/asound.conf'):
        self.filename = filename
        self.config = ""
        self.load_config()

    def load_config(self):
        """ Load the ALSA configuration from a file, or initialize it as empty if not existent. """
        if os.path.exists(self.filename):
            with open(self.filename, 'r') as file:
                self.config = file.read()
        else:
            self.config = ""  # Initialize as empty if the file does not exist
        self.original_checksum = self.calculate_checksum()

    def calculate_checksum(self):
        """ Calculate MD5 checksum of the current configuration. """
        return hashlib.md5(self.config.encode('utf-8')).hexdigest()

    def create_simple_config(self, hw, channels):
        """ Create a simple ALSA configuration using the predefined template. """
        self.config = SIMPLE_CONFIG_TEMPLATE.format(hw=hw, channels=channels)

    def save(self):
        """ Save the configuration to disk only if it has changed. """
        current_checksum = self.calculate_checksum()
        if current_checksum != self.original_checksum:
            with open(self.filename, 'w') as file:
                file.write(self.config)
            self.original_checksum = current_checksum
            return True
        return False

def parse_arguments():
    parser = argparse.ArgumentParser(description="Manage ALSA configuration.")
    parser.add_argument("--default", action='store_true', help="Trigger creation of a default configuration")
    parser.add_argument("--channels", type=int, default=2, help="Set the number of channels")
    parser.add_argument("--hw", type=int, default=0, help="Set the default hardware card number")
    return parser.parse_args()

def main():
    args = parse_arguments()
    alsa_config = ALSAConfig()

    # Execute create_simple_config only if --default is set
    if args.default:
        alsa_config.create_simple_config(hw=args.hw, channels=args.channels)
        if alsa_config.save():
            print("Configuration saved.")
        else:
            print("No changes to save.")
    else:
        print("No --default flag provided, no configuration created.")

if __name__ == "__main__":
    main()


#!/usr/bin/env python3

import os
import sys
import shutil
import logging
import argparse

class CmdlineTxt:
    def __init__(self):
        self.file_path = self._find_cmdline_file()
        self.content = self._read_file()
        self.original_content = self.content

    def _find_cmdline_file(self):
        # Check for the file in /boot/firmware first, then /boot
        possible_paths = ["/boot/firmware/cmdline.txt", "/boot/cmdline.txt"]
        for path in possible_paths:
            if os.path.exists(path):
                logging.info(f"Using cmdline file at: {path}")
                return path
        logging.error("cmdline.txt not found in /boot/firmware or /boot.")
        raise FileNotFoundError("cmdline.txt not found in /boot/firmware or /boot.")

    def _read_file(self):
        with open(self.file_path, "r") as f:
            # The file is expected to be a single line
            content = f.read().strip()
        return content

    def _create_backup(self):
        backup_path = self.file_path + ".backup"
        shutil.copy(self.file_path, backup_path)
        logging.info(f"Backup created at: {backup_path}")

    def save(self):
        if self.content != self.original_content:
            self._create_backup()
            with open(self.file_path, "w") as f:
                # Write a single line with a trailing newline
                f.write(self.content + "\n")
            logging.info("Changes saved to cmdline.txt.")
        else:
            logging.info("No changes made to cmdline.txt.")

    def enable_serial_console(self):
        tokens = self.content.split()
        token = "console=serial0,115200"
        if token not in tokens:
            # Add at the beginning so that serial console comes first.
            tokens.insert(0, token)
            self.content = " ".join(tokens)
            logging.info("Serial console enabled.")
        else:
            logging.info("Serial console already enabled.")

    def disable_serial_console(self):
        tokens = self.content.split()
        token = "console=serial0,115200"
        new_tokens = [t for t in tokens if t != token]
        if len(new_tokens) != len(tokens):
            self.content = " ".join(new_tokens)
            logging.info("Serial console disabled.")
        else:
            logging.info("Serial console already disabled.")

def main():
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

    parser = argparse.ArgumentParser(description="Manage /boot(*/firmware) cmdline.txt serial console setting.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--enable-serial-console", action="store_true", help="Enable the serial console by adding 'console=serial0,115200'.")
    group.add_argument("--disable-serial-console", action="store_true", help="Disable the serial console by removing 'console=serial0,115200'.")

    args = parser.parse_args()

    try:
        cmdline = CmdlineTxt()

        if args.enable_serial_console:
            cmdline.enable_serial_console()
        elif args.disable_serial_console:
            cmdline.disable_serial_console()

        cmdline.save()
        logging.info("cmdline.txt update completed successfully.")
    except Exception as e:
        logging.error(f"An error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()


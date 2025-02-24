#!/usr/bin/env python3

import os
import shutil
import hashlib
import logging
import argparse


class ConfigTxt:
    def __init__(self, file_path="/boot/firmware/config.txt"):
        self.file_path = file_path
        self.lines = []
        self.changes_made = False
        self.original_checksum = None
        self._read_file()

    def _read_file(self):
        """Reads the content of the config file into the buffer and computes its checksum."""
        if not os.path.exists(self.file_path):
            logging.error(f"Config file not found: {self.file_path}")
            raise FileNotFoundError(f"Config file not found: {self.file_path}")

        with open(self.file_path, "r") as file:
            self.lines = file.readlines()

        self.original_checksum = self._compute_checksum(self.lines)

    def _compute_checksum(self, lines):
        """Computes the checksum of the given lines."""
        content = "".join(lines).encode("utf-8")
        return hashlib.sha256(content).hexdigest()

    def save(self):
        """Writes the buffer back to the config file if changes were made and creates a backup if the file has changed."""
        new_checksum = self._compute_checksum(self.lines)
        if new_checksum != self.original_checksum:
            backup_path = self.file_path + ".backup"
            shutil.copy(self.file_path, backup_path)
            logging.info(f"Backup created at: {backup_path}")

            with open(self.file_path, "w") as file:
                file.writelines(self.lines)

            logging.info("Changes saved to the config file.")
            self.changes_made = True
        else:
            self.changes_made = False

    def _update_line(self, prefix, new_line):
        """Updates or adds a line with the specified prefix."""
        updated = False
        for i, line in enumerate(self.lines):
            if line.strip().startswith(prefix):
                self.lines[i] = new_line
                updated = True
                break
        if not updated:
            self.lines.append(new_line)

    def disable_onboard_sound(self):
        self._update_line("dtparam=audio=", "dtparam=audio=off\n")
        logging.info("Onboard sound disabled.")

    def enable_onboard_sound(self):
        self._update_line("dtparam=audio=", "dtparam=audio=on\n")
        logging.info("Onboard sound enabled.")

    def _update_hdmi_sound(self, mode):
        updated = False
        for i, line in enumerate(self.lines):
            if line.strip().startswith("dtoverlay=vc4-kms-v3d"):
                if mode == "noaudio" and ",noaudio" not in line:
                    self.lines[i] = line.strip() + ",noaudio\n"
                    updated = True
                elif mode == "audio" and ",noaudio" in line:
                    self.lines[i] = line.replace(",noaudio", "").strip() + "\n"
                    updated = True

    def disable_hdmi_sound(self):
        self._update_hdmi_sound("noaudio")
        logging.info("HDMI sound disabled.")

    def enable_hdmi_sound(self):
        self._update_hdmi_sound("audio")
        logging.info("HDMI sound enabled.")

    def disable_eeprom(self):
        self._update_line("force_eeprom_read=", "force_eeprom_read=0\n")
        logging.info("EEPROM read disabled.")

    def enable_eeprom(self):
        self._update_line("force_eeprom_read=", "force_eeprom_read=1\n")
        logging.info("EEPROM read enabled.")

    def enable_overlay(self, overlay):
        self.lines.append(f"dtoverlay={overlay}\n")
        logging.info(f"Overlay '{overlay}' enabled.")

    def remove_hifiberry_overlays(self):
        original_length = len(self.lines)
        self.lines = [line for line in self.lines if not line.strip().startswith("dtoverlay=hifiberry")]
        if len(self.lines) < original_length:
            logging.info("All HiFiBerry overlays removed.")

    def _update_interface(self, interface, enable):
        state = "on" if enable else "off"
        self._update_line(f"dtparam={interface}=", f"dtparam={interface}={state}\n")
        logging.info(f"{interface.upper()} interface set to {state}.")

    def enable_i2c(self):
        self._update_interface("i2c_arm", True)

    def disable_i2c(self):
        self._update_interface("i2c_arm", False)

    def enable_spi(self):
        self._update_interface("spi", True)

    def disable_spi(self):
        self._update_interface("spi", False)

    def default_config(self):
        self.remove_hifiberry_overlays()
        self.disable_onboard_sound()
        self.disable_hdmi_sound()
        self.enable_eeprom()
        self.enable_spi()
        self.enable_i2c()
        logging.info("Default configuration applied.")

    def enable_updi(self):
        """
        Enables UPDI by ensuring the following entries exist in the config file:
        - enable_uart=1
        - dtoverlay=uart0
        - dtoverlay=disable-bt
        """
        self._update_line("enable_uart=", "enable_uart=1\n")
        self._update_line("dtoverlay=uart0", "dtoverlay=uart0\n")
        self._update_line("dtoverlay=disable-bt", "dtoverlay=disable-bt\n")
        logging.info("UPDI settings applied. Reboot may be required.")

    # New methods for hat I2C overlay
    def enable_hat_i2c(self):
        overlay_line = "dtoverlay=i2c-gpio,i2c_gpio_sda=0,i2c_gpio_scl=1\n"
        # Prevent duplicates if the line already exists
        if not any(line.strip() == overlay_line.strip() for line in self.lines):
            self.lines.append(overlay_line)
            logging.info("HAT I2C overlay enabled.")

    def disable_hat_i2c(self):
        original_length = len(self.lines)
        self.lines = [line for line in self.lines if line.strip() != "dtoverlay=i2c-gpio,i2c_gpio_sda=0,i2c_gpio_scl=1"]
        if len(self.lines) < original_length:
            logging.info("HAT I2C overlay disabled.")


def main():
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

    parser = argparse.ArgumentParser(description="Manage /boot/firmware/config.txt settings.")
    parser.add_argument("--overlay", type=str, help="Add a dtoverlay with the given parameter.")
    parser.add_argument("--remove-hifiberry", action="store_true", help="Remove all HiFiBerry overlays.")
    parser.add_argument("--disable-onboard-sound", action="store_true", help="Disable onboard sound.")
    parser.add_argument("--enable-onboard-sound", action="store_true", help="Enable onboard sound.")
    parser.add_argument("--disable-hdmi-sound", action="store_true", help="Disable HDMI sound.")
    parser.add_argument("--enable-hdmi-sound", action="store_true", help="Enable HDMI sound.")
    parser.add_argument("--disable-eeprom", action="store_true", help="Disable EEPROM read.")
    parser.add_argument("--enable-eeprom", action="store_true", help="Enable EEPROM read.")
    parser.add_argument("--disable-i2c", action="store_true", help="Disable I2C interface.")
    parser.add_argument("--enable-i2c", action="store_true", help="Enable I2C interface.")
    parser.add_argument("--disable-spi", action="store_true", help="Disable SPI interface.")
    parser.add_argument("--enable-spi", action="store_true", help="Enable SPI interface.")
    parser.add_argument("--default-config", action="store_true", help="Apply the default configuration.")
    parser.add_argument("--report-change", action="store_true", help="Exit with return code 1 if changes were made.")
    parser.add_argument("--enable-updi", action="store_true", help="Enable UPDI settings: enable UART, dtoverlay for uart0, and disable Bluetooth.")
    parser.add_argument("--enable-hat_i2c", action="store_true", help="Enable HAT I2C overlay (dtoverlay=i2c-gpio,i2c_gpio_sda=0,i2c_gpio_scl=1).")
    parser.add_argument("--disable-hat_i2c", action="store_true", help="Disable HAT I2C overlay (dtoverlay=i2c-gpio,i2c_gpio_sda=0,i2c_gpio_scl=1).")
    args = parser.parse_args()

    config = ConfigTxt()

    try:
        if args.default_config:
            config.default_config()

        if args.remove_hifiberry:
            config.remove_hifiberry_overlays()

        if args.overlay:
            config.enable_overlay(args.overlay)

        if args.disable_onboard_sound:
            config.disable_onboard_sound()

        if args.enable_onboard_sound:
            config.enable_onboard_sound()

        if args.disable_hdmi_sound:
            config.disable_hdmi_sound()

        if args.enable_hdmi_sound:
            config.enable_hdmi_sound()

        if args.disable_eeprom:
            config.disable_eeprom()

        if args.enable_eeprom:
            config.enable_eeprom()

        if args.disable_i2c:
            config.disable_i2c()

        if args.enable_i2c:
            config.enable_i2c()

        if args.disable_spi:
            config.disable_spi()

        if args.enable_spi:
            config.enable_spi()

        if args.enable_updi:
            config.enable_updi()

        # New hat I2C overlay handling
        if args.enable_hat_i2c:
            config.enable_hat_i2c()

        if args.disable_hat_i2c:
            config.disable_hat_i2c()

        config.save()

        if args.report_change:
            exit(1 if config.changes_made else 0)

        logging.info("Configuration update completed successfully.")
    except Exception as e:
        logging.error(f"An error occurred: {e}")
        if args.report_change:
            exit(1)


if __name__ == "__main__":
    main()


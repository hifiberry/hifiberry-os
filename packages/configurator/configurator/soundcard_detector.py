#!/usr/bin/env python3

import os
import subprocess
import logging
import argparse
from configurator.configtxt import ConfigTxt
from configurator.hattools import get_hat_info  # Import the get_hat_info module

class SoundcardDetector:
    def __init__(self, config_file="/boot/config.txt", reboot_file="/tmp/reboot"):
        self.config = ConfigTxt(config_file)
        self.reboot_file = reboot_file
        self.detected_card = None
        self.eeprom = 1

    def _run_command(self, command):
        try:
            result = subprocess.check_output(
                command, shell=True, stderr=subprocess.DEVNULL, text=True
            ).strip()
            return result
        except subprocess.CalledProcessError:
            return ""

    def detect_card(self):
        logging.info("Detecting HiFiBerry sound card...")
        found = self._run_command("aplay -l | grep hifiberry | grep -v pcm5102")

        if not found:
            # Use the imported get_hat_info function
            hat_info = get_hat_info()
            hat_card = hat_info.get("product")
            logging.info(f"Retrieved HAT info: {hat_info}")
            self.detected_card = self._map_hat_to_overlay(hat_card)
            if not self.detected_card:
                self.detected_card = self._probe_i2c()
        else:
            logging.info(f"Found HiFiBerry card via aplay: {found}")
            self.detected_card = found

    def _map_hat_to_overlay(self, hat_card):
        card_map = {
            "Amp100": "amp100,automute",
            "DAC+ ADC Pro": "dacplusadcpro",
            "DAC+ ADC": "dacplusadc",
            "DAC2 ADC Pro": "dacplusadcpro",
            "DAC 2 HD": "dacplushd",
            "Digi2 Pro": "digi-pro",
            "Amp3": "amp3",
            "Amp4 Pro": "amp4pro",
            "Amp4": "dacplus-std",
            "DAC8x": "dac8x",
            "DSP 2x4": "dacplusdsp",
            "StudioDAC8x": "dac8x",
        }
        logging.info(f"Mapping HAT card: {hat_card}")
        return card_map.get(hat_card)

    def _probe_i2c(self):
        logging.info("Probing I2C for sound card...")
        self.config.enable_i2c()
        self.config.save()

        i2c_checks = [
            ("0x4a 25", "0x07", "dacplusadcpro"),
            ("0x3b 1", "0x88", "digi"),
            ("0x4d 40", "0x02", "dacplus-std"),
            ("0x1b 0", "0x6c", "amp"),
            ("0x1b 0", "0x60", "amp"),
            ("0x62 17", "0x8c", "dacplushd"),
            ("0x60 2", "0x03", "beo"),
        ]

        for address, expected, card in i2c_checks:
            result = self._run_command(f"i2cget -y 1 {address} 2>/dev/null")
            if result == expected:
                return card

        logging.warning("No I2C-enabled sound card detected.")
        return None

    def configure_card(self):
        if not self.detected_card:
            logging.error("No sound card detected to configure.")
            return

        logging.info(f"Configuring card: {self.detected_card}")
        self.config.remove_hifiberry_overlays()
        self.config.enable_overlay(f"hifiberry-{self.detected_card}")

        if self.eeprom == 0:
            self.config.disable_eeprom()

        self.config.save()
        with open(self.reboot_file, "w") as reboot_file:
            reboot_file.write(f"Configuring {self.detected_card} requires a reboot.\n")

    def detect_and_configure(self, store=False):
        self.detect_card()
        if store:
            self.configure_card()
        else:
            logging.info(f"Detected card: {self.detected_card}")

def main():
    logging.basicConfig(level=logging.INFO)
    parser = argparse.ArgumentParser(description="HiFiBerry Sound Card Detector")
    parser.add_argument("--store", action="store_true", help="Store detected card configuration in config.txt")
    args = parser.parse_args()

    detector = SoundcardDetector()
    detector.detect_and_configure(store=args.store)

if __name__ == "__main__":
    main()



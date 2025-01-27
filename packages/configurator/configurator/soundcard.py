import subprocess
import logging
import argparse
from configurator.hattools import HatReader

# Sound card definitions as a constant dictionary
SOUND_CARD_DEFINITIONS = {
    "DAC8x/ADC8x": {
        "aplay_contains": "DAC8xADC8x",
        "hat_name": "DAC8x",
        "volume_control": None,
        "output_channels": 8,
        "input_channels": 8,
        "features": [],
        "supports_dsp": False,
    },
    "DAC8x": {
        "aplay_contains": "DAC8x",
        "hat_name": "DAC8x",
        "volume_control": None,
        "output_channels": 8,
        "input_channels": 0,
        "features": [],
        "supports_dsp": False,
    },
    "Digi2 Pro": {
        "aplay_contains": "Digi2 Pro",
        "hat_name": "Digi2 Pro",
        "volume_control": "Softvol",
        "output_channels": 2,
        "input_channels": 0,
        "features": ["dsp"],
        "supports_dsp": True,
    },
    "Amp100": {
        "aplay_contains": "Amp100",
        "hat_name": "Amp100",
        "volume_control": "Digital",
        "output_channels": 2,
        "input_channels": 0,
        "features": ["spdifnoclock", "toslink"],
        "supports_dsp": False,
    },
    "Amp3": {
        "aplay_contains": "Amp3",
        "hat_name": "Amp3",
        "volume_control": "A.Mstr Vol",
        "output_channels": 2,
        "input_channels": 0,
        "features": ["usehwvolume"],
        "supports_dsp": False,
    },
    "Amp4": {
        "aplay_contains": "Amp4",
        "hat_name": "Amp4",
        "volume_control": "Digital",
        "output_channels": 2,
        "input_channels": 0,
        "features": ["usehwvolume"],
        "supports_dsp": True,
    },
    "Amp4 Pro": {
        "aplay_contains": "Amp4 Pro",
        "hat_name": "Amp4 Pro",
        "volume_control": "Digital",
        "output_channels": 2,
        "input_channels": 0,
        "features": ["usehwvolume"],
        "supports_dsp": True,
    },
    "DSP 2x4": {
        "aplay_contains": "DSP 2x4",
        "hat_name": "DSP 2x4",
        "volume_control": None,
        "output_channels": 2,
        "input_channels": 0,
        "features": ["dsp"],
        "supports_dsp": False,
    },
    "DAC+ ADC Pro": {
        "aplay_contains": "DAC+ ADC Pro",
        "hat_name": "DAC+ ADC Pro",
        "volume_control": None,
        "output_channels": 2,
        "input_channels": 2,
        "features": ["analoginput"],
        "supports_dsp": False,
    },
    "DAC+ ADC": {
        "aplay_contains": "DAC+ ADC",
        "hat_name": "DAC+ ADC",
        "volume_control": None,
        "output_channels": 2,
        "input_channels": 2,
        "features": ["analoginput"],
        "supports_dsp": False,
    },
    "DAC2 ADC Pro": {
        "aplay_contains": "DAC2 ADC Pro",
        "hat_name": "DAC2 ADC Pro",
        "volume_control": "Digital",
        "output_channels": 2,
        "input_channels": 2,
        "features": ["analoginput"],
        "supports_dsp": True,
    },
    "DAC2 HD": {
        "aplay_contains": "DAC2 HD",
        "hat_name": "DAC2 HD",
        "volume_control": "DAC",
        "output_channels": 2,
        "input_channels": 0,
        "features": [],
        "supports_dsp": True,
    },
    "DAC+ DSP": {
        "aplay_contains": "DAC+DSP",
        "hat_name": "DAC+ DSP",
        "volume_control": None,
        "output_channels": 2,
        "input_channels": 0,
        "features": ["toslink"],
        "supports_dsp": False,
    },
    "DAC+/Amp2": {
        "aplay_contains": "DAC+",
        "hat_name": None,
        "volume_control": None,
        "output_channels": 2,
        "input_channels": 0,
        "features": [],
        "supports_dsp": False,
    },
    "Amp+": {
        "aplay_contains": "AMP",
        "hat_name": None,
        "volume_control": None,
        "output_channels": 2,
        "input_channels": 0,
        "features": [],
        "supports_dsp": False,
    },
    "Digi+ Pro": {
        "aplay_contains": "Digi Pro",
        "hat_name": None,
        "volume_control": None,
        "output_channels": 2,
        "input_channels": 0,
        "features": ["digi"],
        "supports_dsp": True,
    },
    "Digi+": {
        "aplay_contains": "Digi",
        "hat_name": None,
        "volume_control": None,
        "output_channels": 2,
        "input_channels": 0,
        "features": ["digi"],
        "supports_dsp": False,
    },
    "Beocreate 4-Channel Amplifier": {
        "aplay_contains": None,
        "hat_name": "Beocreate 4-Channel Amplifier",
        "volume_control": None,
        "output_channels": 2,
        "input_channels": 0,
        "features": ["dsp", "toslink"],
        "supports_dsp": False,
    },
    "DAC+ Zero/Light/MiniAmp": {
        "aplay_contains": None,
        "hat_name": None,
        "volume_control": None,
        "output_channels": 2,
        "input_channels": 0,
        "features": [],
        "supports_dsp": False,
    },
}


class Soundcard:
    def __init__(
        self,
        name=None,
        volume_control=None,
        output_channels=2,
        input_channels=0,
        features=None,
        hat_name=None,
        supports_dsp=False,
    ):
        if name is None:
            detected_card = self._detect_card()
            if detected_card:
                self.name = detected_card["name"]
                self.volume_control = detected_card.get("volume_control")
                self.output_channels = detected_card.get("output_channels", 2)
                self.input_channels = detected_card.get("input_channels", 0)
                self.features = detected_card.get("features", [])
                self.hat_name = detected_card.get("hat_name")
                self.supports_dsp = detected_card.get("supports_dsp", False)
            else:
                self.name = "Unknown"
                self.volume_control = volume_control
                self.output_channels = output_channels
                self.input_channels = input_channels
                self.features = features or []
                self.hat_name = hat_name
                self.supports_dsp = supports_dsp
        else:
            self.name = name
            self.volume_control = volume_control
            self.output_channels = output_channels
            self.input_channels = input_channels
            self.features = features or []
            self.hat_name = hat_name
            self.supports_dsp = supports_dsp

    def __str__(self):
        return (
            f"Soundcard(name={self.name}, volume_control={self.volume_control}, "
            f"output_channels={self.output_channels}, input_channels={self.input_channels}, "
            f"features={self.features}, hat_name={self.hat_name}, supports_dsp={self.supports_dsp})"
        )

    def _detect_card(self):
        try:
            hat_reader = HatReader()
            try:
                vendor, product = hat_reader.read_hat_product()
                potential_matches = [
                    (card_name, attributes)
                    for card_name, attributes in SOUND_CARD_DEFINITIONS.items()
                    if attributes.get("hat_name") == product
                ]
                if len(potential_matches) == 1:
                    return {"name": potential_matches[0][0], **potential_matches[0][1]}
                elif len(potential_matches) > 1:
                    logging.info(f"Multiple matches for HAT {product}. Using `aplay -l` to distinguish.")
                else:
                    logging.warning(f"No matching HAT found for {product}. Falling back to `aplay -l`.")
            except Exception:
                logging.warning("HatReader detection failed.")

            output = subprocess.check_output("aplay -l", shell=True, text=True).strip()
            if "hifiberry" not in output.lower():
                logging.warning("No HiFiBerry sound card detected.")
                return None

            for card_name, attributes in SOUND_CARD_DEFINITIONS.items():
                aplay_contains = attributes.get("aplay_contains", "").lower()
                if aplay_contains and aplay_contains in output.lower():
                    return {"name": card_name, **attributes}
        except subprocess.CalledProcessError:
            logging.error("Error: Unable to execute `aplay -l`. Ensure ALSA is installed and configured.")

        logging.warning("No matching sound card detected.")
        return None

def main():
    parser = argparse.ArgumentParser(description="Detect and display sound card details.")
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose logging (INFO level).",
    )
    parser.add_argument(
        "-vv",
        "--very-verbose",
        action="store_true",
        help="Enable very verbose logging (DEBUG level).",
    )
    args = parser.parse_args()

    if args.very_verbose:
        logging.basicConfig(level=logging.DEBUG)
    elif args.verbose:
        logging.basicConfig(level=logging.INFO)
    else:
        logging.basicConfig(level=logging.WARNING)

    card = Soundcard()

    print("Sound card details:")
    print(f"Name: {card.name}")
    print(f"Volume Control: {card.volume_control}")
    print(f"Output Channels: {card.output_channels}")
    print(f"Input Channels: {card.input_channels}")
    print(f"Features: {', '.join(card.features) if card.features else 'None'}")
    print(f"HAT Name: {card.hat_name or 'None'}")
    print(f"Supports DSP: {'Yes' if card.supports_dsp else 'No'}")


if __name__ == "__main__":
    main()


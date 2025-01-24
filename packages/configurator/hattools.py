import os
import subprocess
import logging


class HatReader:
    def __init__(self):
        self.logger = logging.getLogger(self.__class__.__name__)

    def read_hat_product(self):
        """Attempts to read the HAT product and vendor information."""
        product = None
        vendor = None

        # Try to directly access the HAT via /sys
        self.logger.debug("Checking for HAT information in /proc/device-tree/hat...")
        if os.path.isfile("/proc/device-tree/hat/product"):
            try:
                with open("/proc/device-tree/hat/product", "r") as f:
                    product = f.read().strip("\0")
                with open("/proc/device-tree/hat/vendor", "r") as f:
                    vendor = f.read().strip("\0")
                self.logger.info("HAT information found via /proc/device-tree.")
            except Exception as e:
                self.logger.error(f"Failed to read HAT information: {e}")
        else:
            self.logger.debug("Falling back to reading EEPROM data via I2C.")
            eepfile = "/tmp/eeprom.eep"
            txtfile = "/tmp/eeprom.txt"

            # Load required kernel modules
            self.logger.debug("Loading kernel modules: i2c_dev, at24")
            subprocess.run(["modprobe", "i2c_dev"], check=False)
            subprocess.run(["modprobe", "at24"], check=False)

            # Identify the correct I2C bus
            device_id = None
            for i in [7, 3, 11, 22]:
                if os.path.isdir(f"/sys/class/i2c-adapter/i2c-{i}"):
                    device_id = i
                    break

            if device_id is None:
                self.logger.error("No suitable I2C adapter found.")
                raise RuntimeError("No suitable I2C adapter found.")

            device_path = f"/sys/class/i2c-adapter/i2c-{device_id}/{device_id}-0050"
            if not os.path.isdir(device_path):
                self.logger.debug(f"Creating new device on I2C bus {device_id}.")
                with open(f"/sys/class/i2c-adapter/i2c-{device_id}/new_device", "w") as f:
                    f.write("24c32 0x50\n")

            # Dump the EEPROM data
            try:
                with open(f"{device_path}/eeprom", "rb") as src, open(eepfile, "wb") as dst:
                    dst.write(src.read())
                self.logger.info("EEPROM data successfully dumped.")
            except FileNotFoundError:
                self.logger.error("EEPROM data could not be read.")
                raise RuntimeError("EEPROM data could not be read.")

            # Decode the EEPROM data
            self.logger.debug("Decoding EEPROM data.")
            subprocess.run(["/usr/bin/eepdump", eepfile, txtfile], stdout=subprocess.DEVNULL)

            if os.path.isfile(txtfile):
                try:
                    with open(txtfile, "r") as f:
                        for line in f:
                            if "vendor " in line:
                                vendor = line.split('"')[1].strip()
                            if "product " in line:
                                product = line.split('"')[1].strip()

                    vendor = vendor or "no vendor"
                    product = product or "no product"
                    self.logger.info("HAT information successfully retrieved.")
                except Exception as e:
                    self.logger.error(f"Error reading decoded EEPROM data: {e}")

            # Clean up temporary files
            try:
                os.remove(txtfile)
                self.logger.debug("Temporary TXT file removed.")
            except FileNotFoundError:
                self.logger.warning("Temporary TXT file not found for cleanup.")

        return vendor, product


def main():
    """Main function to initialize logging and run the HAT reader."""
    logging.basicConfig(
        level=logging.ERROR,  # Set default log level to ERROR
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    logger = logging.getLogger("Main")

    logger.info("Starting HAT Reader...")  # This won't show due to ERROR level
    hat_reader = HatReader()
    try:
        vendor, product = hat_reader.read_hat_product()
        print(f"{vendor}:{product}")
    except Exception as e:
        logger.error(f"An error occurred: {e}")


if __name__ == "__main__":
    main()


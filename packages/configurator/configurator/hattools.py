#!/usr/bin/env python3
import argparse
import os
import sys
import subprocess
import re

def read_file_strip_null(path):
    """Read a file in binary mode, decode as UTF-8, and remove any null bytes."""
    try:
        with open(path, "rb") as f:
            content = f.read().decode("utf-8", errors="ignore")
        return content.replace('\0', '').strip()
    except Exception:
        return ""

def get_hat_info():
    """
    Return a dictionary with keys 'vendor', 'product', and 'uuid'.
    If a value is not found, its value is set to None.
    """
    vendor = None
    product = None
    uuid = None

    # First, try to access HAT info directly via /proc/device-tree/hat
    if os.path.exists("/proc/device-tree/hat/product"):
        prod_str = read_file_strip_null("/proc/device-tree/hat/product")
        vendor_str = read_file_strip_null("/proc/device-tree/hat/vendor")
        uuid_str = read_file_strip_null("/proc/device-tree/hat/uuid")
        product = prod_str if prod_str else None
        vendor = vendor_str if vendor_str else None
        uuid = uuid_str if uuid_str else None
    else:
        EEPFILE = "/tmp/eeprom.eep"
        TXTFILE = "/tmp/eeprom.txt"

        # Load necessary kernel modules
        subprocess.run(["modprobe", "i2c_dev"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["modprobe", "at24"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        # Find the correct I2C adapter by scanning i2c-1 through i2c-30
        devid = None
        for i in range(1, 31):
            adapter_path = f"/sys/class/i2c-adapter/i2c-{i}"
            if os.path.isdir(adapter_path):
                try:
                    ls_output = subprocess.check_output(["ls", "-l", adapter_path], text=True)
                except subprocess.CalledProcessError:
                    ls_output = ""
                if "platform/ffff" in ls_output:
                    devid = i
                    break

        if devid is None:
            print("No suitable I2C adapter found.", file=sys.stderr)
            sys.exit(1)

        # Register new devices if they are not already present
        new_device_path = f"/sys/class/i2c-adapter/i2c-{devid}/new_device"
        device_0050_path = f"/sys/class/i2c-adapter/i2c-{devid}/{devid}-0050"
        device_0053_path = f"/sys/class/i2c-adapter/i2c-{devid}/{devid}-0053"

        if not os.path.isdir(device_0050_path):
            try:
                with open(new_device_path, "w") as f:
                    f.write("24c32 0x50\n")
            except Exception as e:
                print(f"Error writing new_device for 0x50: {e}", file=sys.stderr)
        if not os.path.isdir(device_0053_path):
            try:
                with open(new_device_path, "w") as f:
                    f.write("24c32 0x53\n")
            except Exception as e:
                print(f"Error writing new_device for 0x53: {e}", file=sys.stderr)

        # Dump the EEPROM from device 0x50 if available, else 0x53
        eeprom_source = None
        eeprom_0050 = f"{device_0050_path}/eeprom"
        eeprom_0053 = f"{device_0053_path}/eeprom"
        if os.path.isfile(eeprom_0050):
            eeprom_source = eeprom_0050
        elif os.path.isfile(eeprom_0053):
            eeprom_source = eeprom_0053

        if eeprom_source:
            subprocess.run(["dd", f"if={eeprom_source}", f"of={EEPFILE}"],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            print("No EEPROM file found.", file=sys.stderr)
            sys.exit(1)

        # Convert the EEPROM binary into text form using eepdump
        subprocess.run(["/usr/bin/eepdump", EEPFILE, TXTFILE],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        # Parse the TXTFILE for vendor, product, and uuid information
        if os.path.isfile(TXTFILE):
            with open(TXTFILE, "r") as f:
                for line in f:
                    if "vendor " in line:
                        m = re.search(r'vendor\s+"([^"]+)"', line)
                        if m:
                            vendor = m.group(1).strip() or None
                    elif "product " in line and "product_uuid" not in line:
                        m = re.search(r'product\s+"([^"]+)"', line)
                        if m:
                            product = m.group(1).strip() or None
                    elif "product_uuid " in line:
                        parts = line.split()
                        if len(parts) >= 2:
                            uuid = parts[1].strip() or None
        # Clean up temporary TXTFILE if it exists
        try:
            os.remove(TXTFILE)
        except Exception:
            pass

    return {"vendor": vendor, "product": product, "uuid": uuid}

def main():
    parser = argparse.ArgumentParser(description="Retrieve HAT information")
    parser.add_argument("-a", "--all", action="store_true",
                        help="Display vendor, product, and UUID")
    args = parser.parse_args()

    info = get_hat_info()

    # Convert None values to default strings in main
    vendor = info["vendor"] if info["vendor"] is not None else "no vendor"
    product = info["product"] if info["product"] is not None else "no product"
    uuid = info["uuid"] if info["uuid"] is not None else "unknown"

    if args.all:
        print(f"{vendor}:{product}:{uuid}")
    else:
        print(f"{vendor}:{product}")

if __name__ == "__main__":
    main()


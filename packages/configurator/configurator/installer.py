#!/usr/bin/env python3

import os
import subprocess
import sys
import logging

class SoftwareInstaller:
    def __init__(self, directory):
        self.directory = directory

    def install_debian_dependencies(self):
        debian_file = os.path.join(self.directory, "dependencies.debian")
        if os.path.exists(debian_file):
            with open(debian_file, "r") as file:
                packages = [line.strip() for line in file if line.strip() and not line.startswith("#")]

            if packages:
                logging.info(f"Installing Debian packages: {', '.join(packages)}")
                try:
                    subprocess.run(["sudo", "apt", "update"], check=True)
                    subprocess.run(["sudo", "apt", "install", "-y"] + packages, check=True)
                except subprocess.CalledProcessError as e:
                    logging.error(f"Error installing Debian packages: {e}")
                    sys.exit(1)
        else:
            logging.info("No dependencies.debian file found. Skipping Debian package installation.")

    def install_python_dependencies(self):
        python_file = os.path.join(self.directory, "dependencies.python")
        if os.path.exists(python_file):
            with open(python_file, "r") as file:
                modules = [line.strip() for line in file if line.strip() and not line.startswith("#")]

            if modules:
                logging.info(f"Installing Python modules: {', '.join(modules)}")
                try:
                    subprocess.run([sys.executable, "-m", "pip", "install", "--break-system-packages"] + modules, check=True)
                except subprocess.CalledProcessError as e:
                    logging.error(f"Error installing Python modules: {e}")
                    sys.exit(1)
        else:
            logging.info("No dependencies.python file found. Skipping Python module installation.")

    def run(self):
        self.install_debian_dependencies()
        self.install_python_dependencies()

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

    if len(sys.argv) != 2:
        logging.error("Usage: python installer.py <directory>")
        sys.exit(1)

    directory = sys.argv[1]
    installer = SoftwareInstaller(directory)
    installer.run()


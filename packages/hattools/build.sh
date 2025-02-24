#!/bin/bash

set -e

# Configuration
PACKAGE_NAME="hifiberry-eeprom"
VERSION="1.1.0"
MAINTAINER="HiFiBerry <support@hifiberry.com>"
WORK_DIR="$HOME/src/debian/$PACKAGE_NAME"
OUTPUT_DIR="$HOME/packages"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

function clean() {
    echo "Cleaning up..."
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

function build_package() {
    echo "Preparing package directory..."
    mkdir -p "$WORK_DIR/DEBIAN"
    mkdir -p "$WORK_DIR/opt/hifiberry/eeprom"

    # Copy files from the eeprom directory to the package directory
    if [ ! -d "eeprom" ]; then
        echo "Error: eeprom directory not found!"
        exit 1
    fi
    cp -r eeprom/*.eep eeprom/*.sh "$WORK_DIR/opt/hifiberry/eeprom/"

    # Create the control file
    cat > "$WORK_DIR/DEBIAN/control" <<EOL
Package: $PACKAGE_NAME
Version: $VERSION
Architecture: all
Depends: raspi-utils-eeprom
Maintainer: $MAINTAINER
Priority: optional
Section: utils
Description: HiFiBerry EEPROM tools
 Copies EEPROM files to /opt/hifiberry/eeprom for HiFiBerry management.
EOL

    # Set permissions
    chmod -R 755 "$WORK_DIR"

    # Build the Debian package
    dpkg-deb --build "$WORK_DIR" "$OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_all.deb"
    echo "Package created: $OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_all.deb"
}

# Main logic
case "$1" in
    --clean)
        clean
        ;;
    *)
        clean
        build_package
        ;;
esac


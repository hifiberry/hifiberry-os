#!/bin/bash

set -e

# Configuration
VERSION="1.0.0"
PACKAGE_NAME="pipewire-server"
MAINTAINER="HiFiBerry <support@hifiberry.com>"
WORK_DIR="$(pwd)/${PACKAGE_NAME}"
OUTPUT_DIR="$HOME/packages"
CONFIG_FILE="$(pwd)/pipewire.conf"
POSTINSTALL_SCRIPT="$(pwd)/postinstall"
UNIT_FILE="$(pwd)/pipewire-server.service"

# Install dependencies
function install_dependencies() {
    echo "Installing build dependencies..."
    sudo apt-get update
    sudo apt-get install -y pipewire systemd fakeroot dh-make devscripts
}

# Prepare Debian package structure
function prepare_package_structure() {
    echo "Preparing Debian package structure..."

    # Clean up old directories
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR/DEBIAN" "$WORK_DIR/usr/lib/systemd/system" "$WORK_DIR/etc/pipewire"

    # Verify the presence of required files
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: pipewire.conf not found in the script directory!"
        exit 1
    fi

    if [ ! -f "$POSTINSTALL_SCRIPT" ]; then
        echo "Error: postinstall script not found in the script directory!"
        exit 1
    fi

    if [ ! -f "$UNIT_FILE" ]; then
        echo "Error: pipewire-server.service not found in the script directory!"
        exit 1
    fi

    # Copy the config file
    echo "Copying pipewire.conf to the package..."
    cp "$CONFIG_FILE" "$WORK_DIR/etc/pipewire/pipewire.conf"
    cp asound.conf "$WORK_DIR/etc/asound.conf"

    # Copy the postinstall script
    echo "Copying postinstall script to the package..."
    cp "$POSTINSTALL_SCRIPT" "$WORK_DIR/DEBIAN/postinst"
    chmod +x "$WORK_DIR/DEBIAN/postinst"

    # Copy the systemd unit file
    echo "Copying pipewire-server.service to the package..."
    cp "$UNIT_FILE" "$WORK_DIR/usr/lib/systemd/system/pipewire-server.service"

    # Create the control file
    echo "Creating control file..."
    cat > "$WORK_DIR/DEBIAN/control" <<EOL
Package: $PACKAGE_NAME
Version: $VERSION
Architecture: all
Maintainer: $MAINTAINER
Priority: optional
Section: sound
Depends: pipewire, pipewire-alsa, systemd, pulseaudio-utils, pipewire-pulse
Description: PipeWire media server
 This package installs PipeWire as a system daemon, making it available for use by background processes and system services.
EOL

    # Set permissions for the package structure
    chmod -R 755 "$WORK_DIR"
}

# Build the Debian package
function build_debian_package() {
    echo "Building Debian package..."
    mkdir -p "$OUTPUT_DIR"
    dpkg-deb --build "$WORK_DIR" "$OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_all.deb"
    echo "Debian package created at $OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_all.deb"
}

# Clean temporary files
function clean() {
    echo "Cleaning up temporary files..."
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Main function
case "$1" in
    --clean)
        clean
        ;;
    *)
        install_dependencies
        prepare_package_structure
        build_debian_package
        ;;
esac


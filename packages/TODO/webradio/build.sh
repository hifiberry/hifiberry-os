#!/bin/bash

set -e

# Configuration
VERSION="1.0.0"
PACKAGE_NAME="webradio"
MAINTAINER="HiFiBerry <info@hifiberry.com>"
WORK_DIR="$HOME/src/$PACKAGE_NAME"
OUTPUT_DIR="$HOME/packages"
DEB_BUILD_DIR="$WORK_DIR/deb"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Install dependencies
function install_dependencies() {
    echo "Installing build dependencies..."
    sudo apt-get update
    sudo apt-get install -y fakeroot dh-make devscripts
}

# Prepare Debian package structure
function prepare_debian_structure() {
    echo "Preparing Debian package structure..."

    # Clean up old directories
    rm -rf "$WORK_DIR"
    mkdir -p "$DEB_BUILD_DIR/DEBIAN" "$DEB_BUILD_DIR/usr/bin"

    # Copy the script
    echo "Copying start-radio script to package directory..."
    cp start-radio "$DEB_BUILD_DIR/usr/bin/"
    chmod +x "$DEB_BUILD_DIR/usr/bin/start-radio"

    # Create control file
    cat > "$DEB_BUILD_DIR/DEBIAN/control" <<EOL
Package: $PACKAGE_NAME
Version: $VERSION
Architecture: all
Maintainer: $MAINTAINER
Priority: optional
Section: sound
Depends: curl
Description: Web Radio Script
 A script to start and manage web radio playback.
 Installed in /usr/bin.
EOL

    chmod -R 755 "$DEB_BUILD_DIR"
}

# Build Debian package
function build_debian_package() {
    echo "Building Debian package..."
    dpkg-deb --build "$DEB_BUILD_DIR" "$OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_all.deb"
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
        prepare_debian_structure
        build_debian_package
        ;;
esac


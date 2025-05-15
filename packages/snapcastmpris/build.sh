#!/bin/bash

set -e

# Configuration
VERSION="1.0.0"
PACKAGE_NAME="snapcastmpris"
MAINTAINER="HiFiBerry <info@hifiberry.com>"
WORK_DIR="$HOME/src/$PACKAGE_NAME"
OUTPUT_DIR="$HOME/packages"

# Install dependencies
function install_dependencies() {
    echo "Installing build dependencies..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-setuptools python3-stdeb fakeroot dh-make devscripts
}

# Clone the repository
function prepare_repository() {
    echo "Preparing repository..."
    if [ ! -d "$PACKAGE_NAME" ]; then
        git clone https://github.com/hifiberry/snapcastmpris "$PACKAGE_NAME"
    fi
}

# Build the Debian package using setup.py
function build_debian_package() {
    echo "Building Debian package using setup.py..."

    cd "$PACKAGE_NAME"

    # Clean previous builds
    python3 setup.py clean --all || true

    # Generate the Debian package
    python3 setup.py --command-packages=stdeb.command bdist_deb

    # Check if deb_dist directory exists
    if [ ! -d "deb_dist" ]; then
        echo "Error: 'deb_dist' directory not found. Something went wrong during the build."
        exit 1
    fi

    # Move the resulting .deb files to the output directory
    mkdir -p "$OUTPUT_DIR"
    find "deb_dist" -name "*.deb" -exec cp {} "$OUTPUT_DIR" \;

    cd ..
    echo "Debian packages created and moved to $OUTPUT_DIR"
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
        prepare_repository
        build_debian_package
        ;;
esac


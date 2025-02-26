#!/bin/bash

# Define variables
PACKAGE_NAME="configurator"
VERSION="1.3.0"
OUTPUT_DIR="$HOME/packages"
BUILD_DIR="deb_dist"
PACKAGEFILE="./PACKAGEFILE" # File to store the package name

# Function to clean up build files
clean() {
    echo "Cleaning up build files..."
    rm -rf "$BUILD_DIR"
    rm -rf "$PACKAGE_NAME.egg-info"
    rm -rf build
    rm -rf dist
    rm -f "$PACKAGEFILE"
    rm -rf $PACKAGE_NAME*.tar.gz
    echo "Cleanup completed."
}

# Function to build the package
build_package() {
    echo "Building the Debian package..."
    python3 setup.py --command-packages=stdeb.command bdist_deb

    if [ ! -d "$BUILD_DIR" ]; then
        echo "Build failed. Exiting."
        exit 1
    fi

    # Create output directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR"

    # Find and copy the built package
    echo "find "$BUILD_DIR" -name "${PACKAGE_NAME}_*.deb" ! -name "*dbgsym*" | head -n 1"
    DEB_PACKAGE=$(find "$BUILD_DIR" -name "python*${PACKAGE_NAME}_*.deb" ! -name "*dbgsym*" | head -n 1)
    echo $DEB_PACKAGE

    if [ -n "$DEB_PACKAGE" ]; then
        cp "$DEB_PACKAGE" "$OUTPUT_DIR"
        echo "$(basename "$DEB_PACKAGE")" > "$PACKAGEFILE"
        echo "Build completed. Package copied to $OUTPUT_DIR."
    else
        echo "Failed to find the .deb package to copy."
        exit 1
    fi
}

# Function to install the package
install_package() {
    # Build the package first
    build_package

    # Read the package name from PACKAGEFILE
    if [ -f "$PACKAGEFILE" ]; then
        DEB_PACKAGE=$(cat "$PACKAGEFILE")
    else
        echo "PACKAGEFILE not found. Build the package first."
        exit 1
    fi

    FULL_PATH="$OUTPUT_DIR/$DEB_PACKAGE"

    # Install the package
    if [ -f "$FULL_PATH" ]; then
        echo "Installing the package: $FULL_PATH"
        sudo apt install -y --reinstall "$FULL_PATH"
        echo "Package installed successfully."
    else
        echo "Failed to find the package at $FULL_PATH for installation."
        exit 1
    fi
}

# Check script options
if [ "$1" == "--clean" ]; then
    clean
    exit 0
elif [ "$1" == "--install" ]; then
    install_package
    exit 0
fi

# Default behavior: Build the package
clean
build_package


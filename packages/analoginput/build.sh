#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="hifiberry-analoginput"
SOURCE_DIR="src"
BUILD_DIR="build"

# Function to clean up build files
clean() {
    echo "Cleaning up build files..."
    rm -rf "$BUILD_DIR"
    rm -f ${PACKAGE}*.build ${PACKAGE}*.changes ${PACKAGE}*.dsc ${PACKAGE}*.deb ${PACKAGE}*.buildinfo ${PACKAGE}*.tar.gz
    echo "Cleanup completed."
}

# Check for the --clean option
if [[ "$1" == "--clean" ]]; then
    clean
    exit 0
fi

# Step 1: Create build directory
echo "Preparing build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$PACKAGE"

# Step 2: Copy source files
echo "Copying source files..."
cp -r "$SOURCE_DIR"/* "$BUILD_DIR/$PACKAGE/"

# Step 3: Build the Debian package
echo "Building the Debian package..."
cd "$BUILD_DIR/$PACKAGE"
dpkg-buildpackage -us -uc -b

# Step 4: Move built packages back to package directory
cd ../..
mv "$BUILD_DIR"/${PACKAGE}*.deb . 2>/dev/null || true
mv "$BUILD_DIR"/${PACKAGE}*.build . 2>/dev/null || true
mv "$BUILD_DIR"/${PACKAGE}*.buildinfo . 2>/dev/null || true
mv "$BUILD_DIR"/${PACKAGE}*.changes . 2>/dev/null || true

echo "Debian package build completed."
echo "Package: ${PACKAGE}*.deb"

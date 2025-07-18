#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="hifiberry-btaudio"
SRC_DIR="$PACKAGE"

# Function to clean up build and downloaded files
clean() {
    echo "Cleaning up build files..."
    rm -f "$PACKAGE"_*.build "$PACKAGE"_*.changes "$PACKAGE"_*.dsc "$PACKAGE"_*.buildinfo "$PACKAGE"_*.tar.gz "$PACKAGE"_*.deb
    echo "Cleanup completed."
}

# Check for the --clean option
if [[ "$1" == "--clean" ]]; then
    clean
    exit 0
fi

# Step 1: Check if source directory exists
if [[ ! -d "$SRC_DIR" ]]; then
    echo "Error: Source directory '$SRC_DIR' not found"
    exit 1
fi

echo "Using local source directory: $SRC_DIR"
cd "$SRC_DIR"

# Extract version from debian/changelog
VERSION=$(head -1 debian/changelog | sed 's/.*(\([^)]*\)).*/\1/')
echo "Building version: $VERSION"

# Step 2: Build the Debian package using sbuild
echo "Building Debian package with sbuild..."
sbuild -d stable --chroot-mode=unshare --no-run-lintian

# Step 3: Move the generated files to the package directory
echo "Moving generated files..."
cd ..
mv "$PACKAGE"_*.deb ./ 2>/dev/null || echo "No .deb files to move"
mv "$PACKAGE"_*.dsc ./ 2>/dev/null || echo "No .dsc files to move"
mv "$PACKAGE"_*.tar.gz ./ 2>/dev/null || echo "No .tar.gz files to move"
mv "$PACKAGE"_*.changes ./ 2>/dev/null || echo "No .changes files to move"
mv "$PACKAGE"_*.buildinfo ./ 2>/dev/null || echo "No .buildinfo files to move"
mv "$PACKAGE"_*.build ./ 2>/dev/null || echo "No .build files to move"

echo "Package built successfully"
echo "Built packages:"
ls -la *.deb 2>/dev/null || echo "No packages found"

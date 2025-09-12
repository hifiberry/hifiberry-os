#!/bin/bash

set -e



# Building package with sbuild
echo "Building package with sbuild..."
    
cd src

# Make sure debian/rules is executable
chmod +x debian/rules

# Create a build directory in the current location instead of /tmp
BUILD_DIR="$(pwd)/../sbuild_workspace"
mkdir -p "$BUILD_DIR"

# Use sbuild to build the package with custom build directory
if [ -z "$DIST" ]; then
    sbuild --chroot-mode=unshare --no-clean-source --enable-network --build-dir="$BUILD_DIR"
else
    sbuild --chroot-mode=unshare --no-clean-source --enable-network --dist="$DIST" --build-dir="$BUILD_DIR"
fi

# Go back to parent directory
cd ..

# Clean up the sbuild workspace to save space
rm -rf "$BUILD_DIR" 2>/dev/null || true

echo "Package build completed."
echo "Built packages:"
ls -la src/../*.deb 2>/dev/null || echo "No .deb files found"


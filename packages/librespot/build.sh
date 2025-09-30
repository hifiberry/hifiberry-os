#!/bin/bash
set -e

# Building package with sbuild
echo "Building package with sbuild..."
    
cd src

# Make sure debian/rules is executable
chmod +x debian/rules

# Create a build directory in the current location instead of /tmp
BUILD_DIR="$(pwd)/../sbuild_workspace"
SBUILD_TMPDIR="/var/tmp/sbuild_tmp"
mkdir -p "$BUILD_DIR"
mkdir -p "$SBUILD_TMPDIR"

# Set TMPDIR for sbuild to use /var/tmp
export TMPDIR="$SBUILD_TMPDIR"

echo "Using TMPDIR: $TMPDIR for sbuild"

# Use sbuild to build the package with custom build directory
if [ -z "$DIST" ]; then
    sbuild --chroot-mode=unshare --no-clean-source --enable-network --build-dir="$BUILD_DIR"
else
    sbuild --chroot-mode=unshare --no-clean-source --enable-network --dist="$DIST" --build-dir="$BUILD_DIR"
fi

# Go back to parent directory
cd ..

# Clean up the sbuild workspaces to save space
rm -rf "$BUILD_DIR" 2>/dev/null || true
rm -rf "$SBUILD_TMPDIR" 2>/dev/null || true

echo "Package build completed."
echo "Built packages:"
ls -la src/../*.deb 2>/dev/null || echo "No .deb files found"


#!/bin/bash
set -e

# Enable cross-compile support if configured
_CC_ENV="$(dirname "$0")/../../scripts/cross-compile-env.sh"
if [ -f "$_CC_ENV" ]; then source "$_CC_ENV"; else echo "Not using cross-compilation (${_CC_ENV} does not exist)"; fi

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

# Move build artifacts before cleaning up
echo "Looking for build artifacts..."
find "$BUILD_DIR" -name "*.deb" -exec cp {} . \; 2>/dev/null || true
find "$BUILD_DIR" -name "*.changes" -exec cp {} . \; 2>/dev/null || true
find "$BUILD_DIR" -name "*.buildinfo" -exec cp {} . \; 2>/dev/null || true

# Also check if artifacts are in the source directory
find src -maxdepth 1 -name "*.deb" -exec mv {} . \; 2>/dev/null || true
find src -maxdepth 1 -name "*.changes" -exec mv {} . \; 2>/dev/null || true
find src -maxdepth 1 -name "*.buildinfo" -exec mv {} . \; 2>/dev/null || true

# Clean up the sbuild workspaces to save space
rm -rf "$BUILD_DIR" 2>/dev/null || true
rm -rf "$SBUILD_TMPDIR" 2>/dev/null || true

echo "Package build completed."
echo "Built packages:"
ls -la *.deb 2>/dev/null || echo "No .deb files found"


#!/bin/bash

# Exit on error
set -e

PACKAGE="hifiberry-raat"
VERSION="$(cat $(dirname $(realpath $0))/version.txt | tr -d '\n')"
DIST="bullseye"
CHROOT="${DIST}-amd64-sbuild"
BUILD_DIR="/tmp/${PACKAGE}-build"
SRC_DIR="$(dirname $(realpath $0))/src"
SCRIPT_DIR="$(dirname $(realpath $0))"
REPO_URL="https://github.com/hifiberry/raat"
REPO_DIR="$SRC_DIR/raat"

# Parse arguments
NO_UPDATE=false
for arg in "$@"; do
  case $arg in
    --no-update)
      NO_UPDATE=true
      shift
      ;;
  esac
done

echo "Building $PACKAGE version $VERSION"

# Clone the repository to src/raat if it doesn't exist; otherwise, update it
if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning repository from $REPO_URL to $REPO_DIR..."
    git clone "$REPO_URL" "$REPO_DIR"
else
    if [ "$NO_UPDATE" = false ]; then
        echo "Repository already exists at $REPO_DIR. Updating..."
        cd "$REPO_DIR"
        git pull
        cd "$SCRIPT_DIR"
    else
        echo "Repository already exists at $REPO_DIR, skipping update due to --no-update flag."
    fi
fi

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy source files to build directory
echo "Copying debian/ files..."
cp -r "$SRC_DIR/debian" "$BUILD_DIR/"
echo "Copying configure-raat script..."
cp "$SRC_DIR/configure-raat" "$BUILD_DIR/"
echo "Copying raat.service..."
cp "$SRC_DIR/raat.service" "$BUILD_DIR/"
echo "Copying raat/ directory..."
cp -r "$SRC_DIR/raat" "$BUILD_DIR/"

# Verify the copy worked
echo "Contents of build directory after copy:"
ls -la "$BUILD_DIR"
echo "Contents of raat directory:"
ls -la "$BUILD_DIR/raat" || echo "ERROR: raat directory not found!"

# Change to build directory
cd "$BUILD_DIR"

# Build package using sbuild
echo "Using sbuild..."
sbuild \
    --chroot-mode=unshare \
    --no-clean-source \
    --enable-network \
    --dist="$DIST" \
    --chroot="$CHROOT" \
    --build-dir="$BUILD_DIR" \
    --no-run-lintian \
    --verbose

# Move build artifacts to script directory
echo "Moving build artifacts..."
mv *.deb "$SCRIPT_DIR/" 2>/dev/null || true
mv *.changes "$SCRIPT_DIR/" 2>/dev/null || true
mv *.buildinfo "$SCRIPT_DIR/" 2>/dev/null || true

echo "Package built successfully"
echo "Built packages:"
ls -la "$SCRIPT_DIR"/*.deb 2>/dev/null || echo "No packages found"


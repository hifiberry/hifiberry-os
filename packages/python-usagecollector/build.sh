#!/bin/bash

# Exit on error
set -e

PACKAGE="python3-usagecollector"
VERSION="1.0.0-1"
DIST="${DIST:-bullseye}"
# Check if DIST is set by environment variable
if [ -n "$DIST" ]; then
    echo "Using distribution from DIST environment variable: $DIST"
    DIST_ARG="--dist=$DIST"
else
    echo "No DIST environment variable set, using sbuild default"
    DIST_ARG=""
fi
BUILD_DIR="/tmp/${PACKAGE}-build"
SRC_DIR="$(dirname $(realpath $0))/src"
SCRIPT_DIR="$(dirname $(realpath $0))"
REPO_URL="https://github.com/hifiberry/usagecollector"
REPO_DIR="usagecollector"

echo "Building $PACKAGE version $VERSION"

# Check if changelog version matches build script version
if [ -f "$SRC_DIR/debian/changelog" ]; then
    CHANGELOG_VERSION=$(head -n 1 "$SRC_DIR/debian/changelog" | grep -oP '\(\K[^)]+')
    if [ "$VERSION" != "$CHANGELOG_VERSION" ]; then
        echo "ERROR: Version mismatch between build script ($VERSION) and changelog ($CHANGELOG_VERSION)"
        exit 1
    fi
    echo "Version consistency check passed: $VERSION"
fi

# Clone the repository if it doesn't exist; otherwise, update it
if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning repository from $REPO_URL..."
    git clone "$REPO_URL" "$REPO_DIR"
else
    echo "Repository already exists. Updating..."
    cd "$REPO_DIR"
    git pull
    cd ..
fi

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy source files to build directory
cp -r "$SRC_DIR/"* "$BUILD_DIR/"

# Copy the cloned repository to build directory
cp -r "$REPO_DIR" "$BUILD_DIR/usagecollector-source"

# Change to build directory
cd "$BUILD_DIR"

# Build package using sbuild
echo "Using sbuild..."
sbuild \
    --chroot-mode=unshare \
    --enable-network \
    --no-clean-source \
    $DIST_ARG \
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


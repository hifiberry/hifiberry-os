#!/bin/bash
# Exit on error
set -e

# Enable cross-compile support if configured
_CC_ENV="$(dirname "$0")/../../scripts/cross-compile-env.sh"
if [ -f "$_CC_ENV" ]; then 
    source "$_CC_ENV"
else 
    echo "Not using cross-compilation (${_CC_ENV} does not exist)"
fi

# Define variables
PACKAGE="pipewire-api"
DEB_PACKAGE="pipewire-api"
REPO_URL="https://github.com/LarsGrootkarzijn/pipewire-api"
export BUILD_DIR="/tmp/${PACKAGE}-build"

# Check for DIST environment variable
if [ -n "$DIST" ]; then
    echo "Using distribution from DIST environment variable: $DIST"
    export DIST_ARG="--dist=$DIST"
    export CHROOT_ARG="--chroot=$CHROOT"
else
    export DIST_ARG=""
    export CHROOT_ARG=""
fi

# Function to clean up build and downloaded files
clean() {
    echo "Cleaning up build and downloaded files..."
    rm -rf "$BUILD_DIR"
    rm -rf "$PACKAGE"
    rm -f $PACKAGE*.build $PACKAGE*.changes $PACKAGE*.dsc $PACKAGE*.deb $PACKAGE*.buildinfo $PACKAGE*.tar.gz
    echo "Cleanup completed."
}

# Check for the --clean option
if [[ "$1" == "--clean" ]]; then
    clean
    exit 0
fi

# Function to check version consistency
check_version_consistency() {
    echo "Checking version consistency..."
    
    # Get version from Cargo.toml
    local cargo_version=$(grep -E '^version\s*=\s*"[^"]*"' "$PACKAGE/Cargo.toml" | head -1 | sed -E 's/^version\s*=\s*"([^"]*)"/\1/')
    
    # Get version from VERSION file
    local version_file=$(cat "$PACKAGE/VERSION" | tr -d '\n')
    
    # Get version from debian/changelog
    local debian_version=$(head -1 "$PACKAGE/debian/changelog" | sed -E 's/^[^(]*\(([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
    
    echo "  Cargo.toml version:     $cargo_version"
    echo "  VERSION file:           $version_file"
    echo "  debian/changelog:       $debian_version"
    
    if [[ "$cargo_version" != "$debian_version" ]] || [[ "$version_file" != "$debian_version" ]]; then
        echo "ERROR: Version mismatch detected!"
        echo "  Cargo.toml:     $cargo_version"
        echo "  VERSION file:   $version_file"
        echo "  debian/changelog: $debian_version"
        echo "Please update all version files to match debian/changelog"
        exit 1
    fi
    
    echo "✓ All versions consistent: $debian_version"
}

# Prepare build directory
echo "Preparing build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Clone or update repository
if [[ -d "$PACKAGE/.git" ]]; then
    echo "Updating $PACKAGE source from $REPO_URL..."
    cd "$PACKAGE"
    git pull
else
    echo "Cloning $PACKAGE source from $REPO_URL..."
    git clone "$REPO_URL" "$PACKAGE"
    cd "$PACKAGE"
fi
cd ..

# Check version consistency
check_version_consistency

# Build Debian package
echo "Building $PACKAGE Debian package..."
cd "$PACKAGE"
make deb

# Remove debug symbols
rm -f ../${DEB_PACKAGE}-dbgsym*.deb

# Move built packages to package directory
cd ..
mv $BUILD_DIR/${DEB_PACKAGE}_*.deb . 2>/dev/null || true
mv $BUILD_DIR/${DEB_PACKAGE}_*.build . 2>/dev/null || true
mv $BUILD_DIR/${DEB_PACKAGE}_*.buildinfo . 2>/dev/null || true
mv $BUILD_DIR/${DEB_PACKAGE}_*.changes . 2>/dev/null || true

echo "Package build completed."
echo "Built packages:"
ls -lh ${DEB_PACKAGE}_*.deb 2>/dev/null || echo "No .deb files found"
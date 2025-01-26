#!/bin/bash

set -e

# Configuration
VERSION="v0.31.0"
PACKAGE_NAME="snapcast"
MAINTAINER="HiFiBerry <info@hifiberry.com>"
WORK_DIR="$HOME/src/$PACKAGE_NAME"
OUTPUT_DIR="$HOME/packages"
DEB_BUILD_DIR="$WORK_DIR/deb"

# Install dependencies
function install_dependencies() {
    echo "Installing build dependencies..."
    sudo apt-get update
    sudo apt-get install -y build-essential cmake libasound2-dev libavahi-client-dev \
        libboost-all-dev libcurl4-openssl-dev libssl-dev libopus-dev \
        fakeroot dh-make devscripts
}

# Clone and compile the repository
function compile_binaries() {
    echo "Cloning and compiling Snapcast..."
    if [ ! -d snapcast ]; then
        git clone https://github.com/badaix/snapcast.git
    fi
    cd snapcast
    git checkout "$VERSION"
    mkdir -p build
    cd build
    cmake ..
    make -j$(nproc)
    cd ../..
}

# Prepare Debian package structure
function prepare_debian_structure() {
    echo "Preparing Debian package structure..."

    # Clean up old directories
    rm -rf "$DEB_BUILD_DIR"
    mkdir -p "$DEB_BUILD_DIR/DEBIAN" "$DEB_BUILD_DIR/usr/bin"

    # Copy binaries to the package directory
    echo "Copying binaries to package directory..."
    cp snapcast/bin/snapserver "$DEB_BUILD_DIR/usr/bin/"
    cp snapcast/bin/snapclient "$DEB_BUILD_DIR/usr/bin/"
    chmod +x "$DEB_BUILD_DIR/usr/bin/snapserver" "$DEB_BUILD_DIR/usr/bin/snapclient"

    # Create the control file
    echo "Creating control file..."
    cat > "$DEB_BUILD_DIR/DEBIAN/control" <<EOL
Package: $PACKAGE_NAME
Version: ${VERSION/v/}
Architecture: arm64
Maintainer: $MAINTAINER
Priority: optional
Section: sound
Depends: libasound2, libavahi-client3, libboost-system1.74.0, libcurl4, libssl1.1, libopus0
Description: Snapcast - Synchronous audio player
 Snapcast is a multi-room audio player with support for synchronous audio playback.
 Includes snapserver and snapclient.
EOL

    chmod -R 755 "$DEB_BUILD_DIR"
}

# Build Debian package
function build_debian_package() {
    echo "Building Debian package..."
    mkdir -p "$OUTPUT_DIR"
    dpkg-deb --build "$DEB_BUILD_DIR" "$OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_arm64.deb"
    echo "Debian package created at $OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_arm64.deb"
}

# Clean temporary files
function clean() {
    echo "Cleaning up temporary files..."
    rm -rf "$WORK_DIR" snapcast
    echo "Cleanup complete."
}

# Main function
case "$1" in
    --clean)
        clean
        ;;
    *)
        install_dependencies
        compile_binaries
        prepare_debian_structure
        build_debian_package
        ;;
esac


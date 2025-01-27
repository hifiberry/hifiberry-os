#!/bin/bash

set -e

# Configuration
VERSION="1.0.0"
COMMIT_ID="ed3c82052db4846e8e0da01c5bf8db130db00dee"
PACKAGE_NAME="squeezelite"
MAINTAINER="HiFiBerry <info@hifiberry.com>"
WORK_DIR="$HOME/src/$PACKAGE_NAME"
OUTPUT_DIR="$HOME/packages"
DEB_BUILD_DIR="$WORK_DIR/deb"
UNIT_FILE="squeezelite.service"
START_SCRIPT="start-squeezelite"

# Install dependencies
function install_dependencies() {
    echo "Installing build dependencies..."
    sudo apt-get update
    sudo apt-get install -y build-essential libflac-dev libmad0-dev libvorbis-dev \
        libmpg123-dev libfaad-dev fakeroot dh-make devscripts jq
}

# Clone and prepare the repository
function prepare_repository() {
    echo "Cloning Squeezelite repository..."
    if [ ! -d squeezelite ]; then
        git clone https://github.com/ralph-irving/squeezelite.git
    fi
    cd squeezelite
    git checkout "$COMMIT_ID"
    cd ..
}

# Build Squeezelite
function compile_binaries() {
    echo "Compiling Squeezelite..."
    cd squeezelite
    make
    cd ..
}

# Prepare Debian package structure
function prepare_debian_structure() {
    echo "Preparing Debian package structure..."

    # Clean up old directories
    rm -rf "$WORK_DIR"
    mkdir -p "$DEB_BUILD_DIR/DEBIAN" "$DEB_BUILD_DIR/usr/bin" "$DEB_BUILD_DIR/usr/lib/systemd/system"

    # Copy binaries
    echo "Copying binaries to package directory..."
    cp squeezelite/squeezelite "$DEB_BUILD_DIR/usr/bin/"

    # Copy start-squeezelite script
    if [ -f "$START_SCRIPT" ]; then
        echo "Copying start-squeezelite script to package directory..."
        cp "$START_SCRIPT" "$DEB_BUILD_DIR/usr/bin/"
        chmod +x "$DEB_BUILD_DIR/usr/bin/$START_SCRIPT"
    else
        echo "Error: $START_SCRIPT not found in the current directory."
        exit 1
    fi

    # Copy systemd unit file
    echo "Installing systemd unit file..."
    cp "$UNIT_FILE" "$DEB_BUILD_DIR/usr/lib/systemd/system/"

    # Create control file
    cat > "$DEB_BUILD_DIR/DEBIAN/control" <<EOL
Package: $PACKAGE_NAME
Version: $VERSION
Architecture: arm64
Maintainer: $MAINTAINER
Priority: optional
Section: sound
Depends: libflac12, libmad0, libvorbis0a, libmpg123-0, libfaad2, jq
Description: Squeezelite - Lightweight Squeezebox player
 Squeezelite is a small headless squeezebox emulator for Linux.
 This package includes the Squeezelite binary and helper scripts.
EOL

    # Create postinst script for enabling the service
    echo "Creating postinst script..."
    cat > "$DEB_BUILD_DIR/DEBIAN/postinst" <<EOL
#!/bin/bash
set -e

# Enable and start Squeezelite service
systemctl daemon-reload
systemctl enable squeezelite.service

#DEBHELPER#
EOL

    chmod +x "$DEB_BUILD_DIR/DEBIAN/postinst"
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
    rm -rf "$WORK_DIR" squeezelite
    echo "Cleanup complete."
}

# Main function
case "$1" in
    --clean)
        clean
        ;;
    *)
        install_dependencies
        prepare_repository
        compile_binaries
        prepare_debian_structure
        build_debian_package
        ;;
esac


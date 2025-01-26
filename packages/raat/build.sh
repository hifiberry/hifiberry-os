#!/bin/bash

set -e

# Configuration
VERSION="1.0.0"
PACKAGE_NAME="raat"
MAINTAINER="HiFiBerry <support@hifiberry.com>"
WORK_DIR="$HOME/src/$PACKAGE_NAME"
OUTPUT_DIR="$HOME/packages"
DEB_BUILD_DIR="$WORK_DIR/deb"
INSTALL_DIR="$WORK_DIR/bin/install"

# Install dependencies
function install_dependencies() {
    echo "Installing build dependencies..."
    sudo apt-get update
    sudo apt-get install -y libglib2.0-dev libdbus-1-dev libdbus-glib-1-dev build-essential fakeroot dh-make devscripts
}

# Clone and compile the repository
function compile_binaries() {
    echo "Cloning and compiling raat..."
    if [ ! -d raat ]; then
        git clone https://github.com/hifiberry/raat
    fi
    cd raat
    ./compile64
    cd ..
}

# Prepare Debian package structure
function prepare_debian_structure() {
    echo "Preparing Debian package structure..."

    # Clean up old directories
    rm -rf "$WORK_DIR"
    mkdir -p "$INSTALL_DIR" "$DEB_BUILD_DIR/DEBIAN" "$DEB_BUILD_DIR/usr/bin" "$DEB_BUILD_DIR/usr/lib/systemd/system"

    # Copy binaries to the package directory, excluding .a files
    echo "Copying binaries to package directory..."
    find raat/bin/release/linux/aarch64/ -type f ! -name '*.a' -exec cp {} "$DEB_BUILD_DIR/usr/bin/" \;

    # Copy systemd unit file
    echo "Copying systemd unit file..."
    cp raat.service "$DEB_BUILD_DIR/usr/lib/systemd/system/"

    # Copy the configure-raat script
    echo "Copying configure-raat script..."
    cp configure-raat "$DEB_BUILD_DIR/usr/bin/"
    chmod +x "$DEB_BUILD_DIR/usr/bin/configure-raat"

    # Create control file
    cat > "$DEB_BUILD_DIR/DEBIAN/control" <<EOL
Package: $PACKAGE_NAME
Version: $VERSION
Architecture: arm64
Maintainer: $MAINTAINER
Priority: optional
Section: sound
Depends: libglib2.0-0, libdbus-1-3, libdbus-glib-1-2
Description: RAAT binaries
 RAAT binaries for HiFiBerry audio solutions.
 Installed in /usr/bin.
EOL

    # Create postinst script to enable and start systemd service
    cat > "$DEB_BUILD_DIR/DEBIAN/postinst" <<'EOL'
#!/bin/bash
set -e

# Reload systemd configuration
if command -v systemctl >/dev/null; then
    systemctl daemon-reload
    systemctl enable raat.service
    systemctl start raat.service
fi
EOL
    chmod +x "$DEB_BUILD_DIR/DEBIAN/postinst"

    # Create prerm script to stop and disable the service before removal
    cat > "$DEB_BUILD_DIR/DEBIAN/prerm" <<'EOL'
#!/bin/bash
set -e

# Stop and disable systemd service
if command -v systemctl >/dev/null; then
    systemctl stop raat.service || true
    systemctl disable raat.service || true
fi
EOL
    chmod +x "$DEB_BUILD_DIR/DEBIAN/prerm"

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
    rm -rf "$WORK_DIR" raat
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


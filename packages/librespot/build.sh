#!/bin/bash

set -e

# Configuration
VERSION="v0.4.2" # Replace with the desired version
PACKAGE_NAME="librespot"
MAINTAINER="HiFiBerry <info@hifiberry.com>"
WORK_DIR="$HOME/src/$PACKAGE_NAME"
OUTPUT_DIR="$HOME/packages"
DEB_BUILD_DIR="$WORK_DIR/deb"
INSTALL_DIR="$WORK_DIR/bin/install"
ARCH="arm64" # Set architecture to arm64

# Install dependencies
function install_dependencies() {
    echo "Installing build dependencies..."
    sudo apt-get update
    sudo apt-get install -y build-essential cargo fakeroot dh-make devscripts libasound2-dev
}

# Clone and compile the repository
function compile_binaries() {
    echo "Cloning and compiling librespot..."
    if [ ! -d librespot ]; then
        git clone https://github.com/librespot-org/librespot.git
    fi
    cd librespot
    git checkout "$VERSION"
    cargo build --release --target aarch64-unknown-linux-gnu
    cd ..
}

# Prepare Debian package structure
function prepare_debian_structure() {
    echo "Preparing Debian package structure..."

    # Clean up old directories
    rm -rf "$WORK_DIR"
    mkdir -p "$INSTALL_DIR" "$DEB_BUILD_DIR/DEBIAN" "$DEB_BUILD_DIR/usr/bin" "$DEB_BUILD_DIR/usr/lib/systemd/system"

    # Copy binary to the package directory
    echo "Copying binary to package directory..."
    cp librespot/target/aarch64-unknown-linux-gnu/release/librespot "$DEB_BUILD_DIR/usr/bin/"
    chmod +x "$DEB_BUILD_DIR/usr/bin/librespot"

    # Create systemd unit file
    echo "Creating systemd unit file..."
    cat > "$DEB_BUILD_DIR/usr/lib/systemd/system/librespot.service" <<EOL
[Unit]
Description=Librespot - Spotify Connect Client
After=network.target

[Service]
ExecStart=/usr/bin/librespot
Restart=always
RestartSec=10
User=librespot
Group=audio

[Install]
WantedBy=multi-user.target
EOL

    chmod 644 "$DEB_BUILD_DIR/usr/lib/systemd/system/librespot.service"

    # Create postinst script for user creation
    echo "Creating postinst script..."
    cat > "$DEB_BUILD_DIR/DEBIAN/postinst" <<EOL
#!/bin/bash
set -e

# Create the librespot user and add to the audio group
if ! id -u librespot > /dev/null 2>&1; then
    useradd -r -M -G audio -s /usr/sbin/nologin librespot
    echo "Created librespot user and added it to the audio group."
fi

# Reload systemd and enable the service
systemctl daemon-reload
systemctl enable librespot.service

#DEBHELPER#
EOL
    chmod +x "$DEB_BUILD_DIR/DEBIAN/postinst"

    # Create the control file
    echo "Creating control file..."
    cat > "$DEB_BUILD_DIR/DEBIAN/control" <<EOL
Package: $PACKAGE_NAME
Version: ${VERSION/v/}
Architecture: $ARCH
Maintainer: $MAINTAINER
Priority: optional
Section: sound
Depends: libasound2
Description: Librespot - Spotify Connect Client
 Librespot is an open source client library for Spotify. It enables Spotify Connect functionality for devices.
 Installed in /usr/bin and includes a systemd service to run as a daemon.
EOL

    chmod -R 755 "$DEB_BUILD_DIR"
}

# Build Debian package
function build_debian_package() {
    echo "Building Debian package..."
    mkdir -p "$OUTPUT_DIR"
    dpkg-deb --build "$DEB_BUILD_DIR" "$OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
    echo "Debian package created at $OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
}

# Clean temporary files
function clean() {
    echo "Cleaning up temporary files..."
    rm -rf "$WORK_DIR" librespot
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


#!/bin/bash

set -e

# Configuration
VERSION="0.3.4"  # Replace with the desired version
PACKAGE_NAME="spotifyd"
MAINTAINER="HiFiBerry <info@hifiberry.com>"
WORK_DIR="$HOME/src/$PACKAGE_NAME"
OUTPUT_DIR="$HOME/packages"
DEB_BUILD_DIR="$WORK_DIR/deb"
INSTALL_DIR="$WORK_DIR/bin/install"

# Install dependencies
function install_dependencies() {
    echo "Installing build dependencies..."
    sudo apt-get update
    sudo apt-get install -y build-essential cargo libasound2-dev libssl-dev pkg-config fakeroot dh-make devscripts
}

# Clone and compile spotifyd
function compile_binaries() {
    echo "Cloning and compiling spotifyd..."
    if [ ! -d spotifyd ]; then
        git clone https://github.com/Spotifyd/spotifyd.git
    fi
    cd spotifyd
    git checkout "v$VERSION"
    cargo build --release
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
    cp spotifyd/target/release/spotifyd "$DEB_BUILD_DIR/usr/bin/"
    chmod +x "$DEB_BUILD_DIR/usr/bin/spotifyd"

    # Create systemd unit file
    echo "Creating systemd unit file..."
    cat > "$DEB_BUILD_DIR/usr/lib/systemd/system/spotifyd.service" <<EOL
[Unit]
Description=Spotify Daemon
Documentation=https://github.com/Spotifyd/spotifyd
After=network.target

[Service]
ExecStart=/usr/bin/spotifyd --no-daemon
Restart=always
RestartSec=10
User=spotifyd
Group=audio

[Install]
WantedBy=multi-user.target
EOL

    chmod 644 "$DEB_BUILD_DIR/usr/lib/systemd/system/spotifyd.service"

    # Create postinst script for user creation
    echo "Creating postinst script..."
    cat > "$DEB_BUILD_DIR/DEBIAN/postinst" <<EOL
#!/bin/bash
set -e

# Create the spotifyd user and add to the audio group
if ! id -u spotifyd > /dev/null 2>&1; then
    useradd -r -M -G audio -s /usr/sbin/nologin spotifyd
    echo "Created spotifyd user and added it to the audio group."
fi

# Reload systemd and enable the service
systemctl daemon-reload
systemctl enable spotifyd.service

#DEBHELPER#
EOL
    chmod +x "$DEB_BUILD_DIR/DEBIAN/postinst"

    # Create the control file
    echo "Creating control file..."
    cat > "$DEB_BUILD_DIR/DEBIAN/control" <<EOL
Package: $PACKAGE_NAME
Version: $VERSION
Architecture: amd64
Maintainer: $MAINTAINER
Priority: optional
Section: sound
Depends: libasound2, libssl3
Description: Spotify Daemon
 Spotifyd is a Spotify client that works as a daemon and can be controlled via Spotify Connect.
 A dedicated system user is created and added to the audio group to run the service.
EOL

    chmod -R 755 "$DEB_BUILD_DIR"
}

# Build Debian package
function build_debian_package() {
    echo "Building Debian package..."
    mkdir -p "$OUTPUT_DIR"
    dpkg-deb --build "$DEB_BUILD_DIR" "$OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_amd64.deb"
    echo "Debian package created at $OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_amd64.deb"
}

# Clean temporary files
function clean() {
    echo "Cleaning up temporary files..."
    rm -rf "$WORK_DIR" spotifyd
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


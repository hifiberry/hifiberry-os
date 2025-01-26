#!/bin/bash

set -e

# Configuration
VERSION="1.0.0"
PACKAGE_NAME="pipewire-server"
MAINTAINER="HiFiBerry <info@hifiberry.com>"
WORK_DIR="$(pwd)/${PACKAGE_NAME}"
OUTPUT_DIR="$HOME/packages"
CONFIG_FILE="$(pwd)/pipewire.conf"

# Install dependencies
function install_dependencies() {
    echo "Installing build dependencies..."
    sudo apt-get update
    sudo apt-get install -y pipewire systemd fakeroot dh-make devscripts
}

# Prepare Debian package structure
function prepare_package_structure() {
    echo "Preparing Debian package structure..."

    # Clean up old directories
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR/DEBIAN" "$WORK_DIR/usr/lib/systemd/system" "$WORK_DIR/etc/pipewire"

    # Verify the presence of the config file
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: pipewire.conf not found in the script directory!"
        exit 1
    fi

    # Copy the config file
    echo "Copying pipewire.conf to the package..."
    cp "$CONFIG_FILE" "$WORK_DIR/etc/pipewire/pipewire.conf"

    # Create the systemd unit file
    echo "Creating systemd unit file..."
    cat > "$WORK_DIR/usr/lib/systemd/system/pipewire-server.service" <<EOL
[Unit]
Description=PipeWire Media Server
Documentation=man:pipewire(1)
Wants=pipewire.service
After=network.target

[Service]
ExecStart=/usr/bin/pipewire -c /etc/pipewire/pipewire.conf
Restart=always
User=root
Group=audio
Environment=PIPEWIRE_RUNTIME_DIR=/run/pipewire
AmbientCapabilities=CAP_SYS_ADMIN CAP_NET_ADMIN
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL

    # Create the control file
    echo "Creating control file..."
    cat > "$WORK_DIR/DEBIAN/control" <<EOL
Package: $PACKAGE_NAME
Version: $VERSION
Architecture: all
Maintainer: $MAINTAINER
Priority: optional
Section: sound
Depends: pipewire, systemd
Description: PipeWire media server
 This package installs PipeWire as a system daemon, making it available for use by background processes and system services.
EOL

    # Add postinst script to enable and start the service
    echo "Creating postinst script..."
    cat > "$WORK_DIR/DEBIAN/postinst" <<EOL
#!/bin/bash
set -e

# Create the runtime directory with the correct permissions
if [ ! -d /run/pipewire ]; then
    mkdir -p /run/pipewire
    chmod 1777 /run/pipewire
fi

# Create tmpfiles configuration for persistence
echo "d /run/pipewire 0777 root root -" > /etc/tmpfiles.d/pipewire.conf
systemd-tmpfiles --create /etc/tmpfiles.d/pipewire.conf

# Enable and start the service
systemctl daemon-reload
systemctl enable pipewire-server.service
systemctl start pipewire-server.service
EOL

    chmod +x "$WORK_DIR/DEBIAN/postinst"

    # Set permissions for the package structure
    chmod -R 755 "$WORK_DIR"
}

# Build the Debian package
function build_debian_package() {
    echo "Building Debian package..."
    mkdir -p "$OUTPUT_DIR"
    dpkg-deb --build "$WORK_DIR" "$OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_all.deb"
    echo "Debian package created at $OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_all.deb"
}

# Clean temporary files
function clean() {
    echo "Cleaning up temporary files..."
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Main function
case "$1" in
    --clean)
        clean
        ;;
    *)
        install_dependencies
        prepare_package_structure
        build_debian_package
        ;;
esac


#!/bin/bash

set -e

# Define package name, version, and directories
PKG_NAME=audiocontrol
VERSION=1.0.0
BUILD_DIR=$HOME/hifiberry-os/packages/$PKG_NAME/build
DEBIAN_DIR=$BUILD_DIR/DEBIAN
SYSTEMD_DIR=$BUILD_DIR/etc/systemd/system
CONFIG_DIR=$BUILD_DIR/etc/audiocontrol2
FINAL_DEST_DIR=$HOME/packages

# Cleanup old build directory if it exists
rm -rf $BUILD_DIR

# Create necessary directories
mkdir -p $DEBIAN_DIR $SYSTEMD_DIR $CONFIG_DIR

# Ensure destination directory exists
mkdir -p $FINAL_DEST_DIR

# Create control file
cat > $DEBIAN_DIR/control <<EOF
Package: $PKG_NAME
Version: $VERSION
Section: sound
Priority: optional
Architecture: all
Depends: python3-audiocontrol2 (>= 1.0.0), python3-socketio, python3-mpd
Maintainer: HiFiBerry <support@hifiberry.com>
Description: Systemd unit and configurations for Audio Control 2
 This package provides systemd integration and default configurations for Audio Control 2.
EOF

# Create systemd service file
cat > $SYSTEMD_DIR/audiocontrol2.service <<EOF
[Unit]
Description=Audio Control 2 Service
After=network.target pipewire-system.service

[Service]
ExecStart=/usr/bin/audiocontrol2
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# Create default configuration file
cat > $CONFIG_DIR/audiocontrol2.conf.default <<EOF
# Default Configuration for Audio Control 2
# Customize this file as needed.
EOF

# Create postinst script
cat > $DEBIAN_DIR/postinst <<EOF
#!/bin/bash
systemctl daemon-reload
systemctl enable audiocontrol2.service
EOF

# Create prerm script
cat > $DEBIAN_DIR/prerm <<EOF
#!/bin/bash
systemctl disable audiocontrol2.service
systemctl stop audiocontrol2.service
EOF

# Make postinst and prerm scripts executable
chmod +x $DEBIAN_DIR/postinst $DEBIAN_DIR/prerm

# Build the package outside of the build directory to prevent inclusion of unwanted files
(cd $BUILD_DIR/.. && dpkg-deb --build $(basename $BUILD_DIR))

# Move the final .deb package to the final destination
mv $BUILD_DIR/../$(basename $BUILD_DIR).deb $FINAL_DEST_DIR/${PKG_NAME}_${VERSION}_all.deb

# Cleanup build directory
rm -rf $BUILD_DIR

# Output the result
echo "Debian package created and located at: $FINAL_DEST_DIR/${PKG_NAME}_${VERSION}_all.deb"


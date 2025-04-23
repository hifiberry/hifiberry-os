#!/bin/bash

set -e

# Configuration
# Check if SPOTIFYD_VERSION is provided, fail if not
if [ -z "${SPOTIFYD_VERSION}" ]; then
    echo "ERROR: SPOTIFYD_VERSION environment variable not set"
    echo "This variable must be set from build.sh"
    exit 1
fi

# Set required environment variables for dh_make
export USER=root
export LOGNAME=root
export DEBFULLNAME="HiFiBerry"
export DEBEMAIL="support@hifiberry.com"

PACKAGE_NAME="hifiberry-spotifyd"
SOURCE_PACKAGE_NAME="spotifyd"
MAINTAINER="HiFiBerry <support@hifiberry.com>"
SOURCE_URL="https://github.com/Spotifyd/spotifyd.git"
WORK_DIR="/tmp/debian"
BUILD_DIR="${WORK_DIR}/${SOURCE_PACKAGE_NAME}-${SPOTIFYD_VERSION}"
OUTPUT_DIR=${OUT_DIR:-/out}

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

echo "===== Building Spotifyd ====="
echo "Preparing working directory..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "Cloning Spotifyd repository..."
git clone "$SOURCE_URL" "$SOURCE_PACKAGE_NAME"
cd "$SOURCE_PACKAGE_NAME"
git checkout "v${SPOTIFYD_VERSION}"

echo "Building Spotifyd..."
cargo build --release

echo "Preparing Debian package..."
mkdir -p "$BUILD_DIR"
cd "$WORK_DIR"

# Create Debian package directory structure
mkdir -p "${BUILD_DIR}/DEBIAN"
mkdir -p "${BUILD_DIR}/usr/bin"
mkdir -p "${BUILD_DIR}/lib/systemd/system"

# Copy binary to package directory
cp "${SOURCE_PACKAGE_NAME}/target/release/spotifyd" "${BUILD_DIR}/usr/bin/"

# Copy systemd service file
cp "/build/systemd/spotifyd.service" "${BUILD_DIR}/lib/systemd/system/"

# Create control file
cat > "${BUILD_DIR}/DEBIAN/control" <<EOL
Package: ${PACKAGE_NAME}
Version: ${SPOTIFYD_VERSION}
Section: sound
Priority: optional
Architecture: $(dpkg --print-architecture)
Maintainer: ${MAINTAINER}
Depends: libasound2, libssl3
Provides: spotifyd
Conflicts: spotifyd
Replaces: spotifyd
Description: HiFiBerry Spotify Daemon
 A Spotify client running as a UNIX daemon.
 This package provides a client for the Spotify music service
 that can be controlled via Spotify Connect from any device.
 This is the HiFiBerry customized version.
EOL

# Create postinst script
cat > "${BUILD_DIR}/DEBIAN/postinst" <<EOL
#!/bin/bash
set -e

# Create spotifyd group if it doesn't exist
if ! getent group spotifyd > /dev/null; then
    groupadd -r spotifyd
fi

# Create spotifyd user if it doesn't exist
if ! getent passwd spotifyd > /dev/null; then
    useradd -r -M -g spotifyd -G audio -s /usr/sbin/nologin spotifyd
fi

# Enable and start systemd service
if [ -x /bin/systemctl ] || [ -x /usr/bin/systemctl ]; then
    systemctl daemon-reload || true
    systemctl enable spotifyd.service || true
    systemctl restart spotifyd.service || true
fi

#DEBHELPER#
exit 0
EOL
chmod 755 "${BUILD_DIR}/DEBIAN/postinst"

# Create prerm script
cat > "${BUILD_DIR}/DEBIAN/prerm" <<EOL
#!/bin/bash
set -e

# Stop and disable systemd service on package removal
if [ "\$1" = "remove" ] || [ "\$1" = "purge" ]; then
    if [ -x /bin/systemctl ] || [ -x /usr/bin/systemctl ]; then
        systemctl stop spotifyd.service || true
        systemctl disable spotifyd.service || true
    fi
fi

#DEBHELPER#
exit 0
EOL
chmod 755 "${BUILD_DIR}/DEBIAN/prerm"

# Set permissions
chmod 755 "${BUILD_DIR}/usr/bin/spotifyd"
chmod 644 "${BUILD_DIR}/lib/systemd/system/spotifyd.service"

echo "Building the Debian package..."
cd "$WORK_DIR"
dpkg-deb --build "$BUILD_DIR"
PKG_NAME="${PACKAGE_NAME}_${SPOTIFYD_VERSION}_$(dpkg --print-architecture).deb"
mv "${SOURCE_PACKAGE_NAME}-${SPOTIFYD_VERSION}.deb" "${OUTPUT_DIR}/${PKG_NAME}"
echo "Package created: ${OUTPUT_DIR}/${PKG_NAME}"
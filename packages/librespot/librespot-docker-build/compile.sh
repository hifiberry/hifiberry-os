#!/bin/bash

set -e

# Configuration
# Check if LIBRESPOT_VERSION is provided, fail if not
if [ -z "${LIBRESPOT_VERSION}" ]; then
    echo "ERROR: LIBRESPOT_VERSION environment variable not set"
    echo "This variable must be set from build.sh"
    exit 1
fi

# Set required environment variables for dh_make
export USER=root
export LOGNAME=root
export DEBFULLNAME="HiFiBerry"
export DEBEMAIL="info@hifiberry.com"

PACKAGE_NAME="hifiberry-librespot"
SOURCE_PACKAGE_NAME="librespot"
MAINTAINER="HiFiBerry <info@hifiberry.com>"
WORK_DIR="/tmp/debian"
BUILD_DIR="${WORK_DIR}/${SOURCE_PACKAGE_NAME}-${LIBRESPOT_VERSION}"
OUTPUT_DIR=${OUT_DIR:-/out}

# Ensure output directories exist
mkdir -p "$OUTPUT_DIR"
mkdir -p "$WORK_DIR"
mkdir -p "$BUILD_DIR"

cd "$WORK_DIR"

echo "===== Building Librespot ====="
echo "Cloning Librespot repository..."
git clone https://github.com/librespot-org/librespot.git
cd librespot

# If a specific commit ID is provided, use that, otherwise use the tag corresponding to the version
if [ -n "${COMMIT_ID}" ]; then
    echo "Checking out specific commit ${COMMIT_ID}..."
    git checkout "${COMMIT_ID}"
else
    echo "Checking out version ${LIBRESPOT_VERSION}..."
    git checkout "v${LIBRESPOT_VERSION}"
fi

# Build the binary with specified features
echo "Building Librespot binary..."
cargo build --release --no-default-features --features "alsa-backend with-libmdns"

# Create package structure
echo "Creating package structure..."
PKG_DIR="${WORK_DIR}/package"
mkdir -p "${PKG_DIR}/DEBIAN"
mkdir -p "${PKG_DIR}/usr/bin"
mkdir -p "${PKG_DIR}/lib/systemd/system"

# Copy the binary to the package
echo "Copying binary and service file..."
cp "target/release/librespot" "${PKG_DIR}/usr/bin/"
cp "${BUILD_DIR}/librespot.service" "${PKG_DIR}/lib/systemd/system/"

# Create control file
echo "Creating Debian control file..."
cat > "${PKG_DIR}/DEBIAN/control" << EOL
Package: ${PACKAGE_NAME}
Version: ${LIBRESPOT_VERSION}
Architecture: arm64
Maintainer: ${MAINTAINER}
Priority: optional
Section: sound
Depends: libasound2, libssl3 | libssl1.1, libc6, libdbus-1-3, libglib2.0-0
Provides: librespot
Conflicts: librespot
Replaces: librespot
Description: HiFiBerry Librespot Spotify Connect player
 An open source client library for Spotify, enabling applications to use
 Spotify Connect directly without having to use the official Spotify app.
 This package provides the librespot binary optimized for HiFiBerry devices.
EOL

# Create postinst script
echo "Creating postinst script..."
cat > "${PKG_DIR}/DEBIAN/postinst" << EOL
#!/bin/bash
set -e

# Create librespot user and group if they don't exist
if ! getent group librespot > /dev/null; then
    addgroup --quiet --system librespot
fi
if ! getent passwd librespot > /dev/null; then
    adduser --quiet --system --ingroup librespot --no-create-home --home /var/lib/librespot librespot
    usermod -a -G audio librespot
fi

# Create home directory for librespot if it doesn't exist
if [ ! -d /var/lib/librespot ]; then
    mkdir -p /var/lib/librespot
    chown librespot:librespot /var/lib/librespot
fi

# Enable the librespot service
systemctl daemon-reload
systemctl enable librespot.service

#DEBHELPER#
exit 0
EOL
chmod +x "${PKG_DIR}/DEBIAN/postinst"

# Create prerm script
echo "Creating prerm script..."
cat > "${PKG_DIR}/DEBIAN/prerm" << EOL
#!/bin/bash
set -e

# Stop and disable the Librespot service on package removal
if [ "\$1" = "remove" ] || [ "\$1" = "purge" ]; then
    systemctl stop librespot.service || true
    systemctl disable librespot.service || true
fi

#DEBHELPER#
exit 0
EOL
chmod +x "${PKG_DIR}/DEBIAN/prerm"

# Create postrm script
echo "Creating postrm script..."
cat > "${PKG_DIR}/DEBIAN/postrm" << EOL
#!/bin/bash
set -e

if [ "\$1" = "purge" ]; then
    # Remove librespot user and group
    if getent passwd librespot > /dev/null; then
        deluser --quiet --system librespot || true
    fi
    if getent group librespot > /dev/null; then
        delgroup --quiet --system librespot || true
    fi
    
    # Remove home directory
    rm -rf /var/lib/librespot || true
fi

#DEBHELPER#
exit 0
EOL
chmod +x "${PKG_DIR}/DEBIAN/postrm"

# Build Debian package
echo "Building Debian package..."
PKG_NAME="${PACKAGE_NAME}_${LIBRESPOT_VERSION}_arm64.deb"
dpkg-deb --build "${PKG_DIR}" "${OUTPUT_DIR}/${PKG_NAME}"

echo "Package build complete: ${OUTPUT_DIR}/${PKG_NAME}"
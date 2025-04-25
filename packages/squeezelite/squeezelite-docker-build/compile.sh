#!/bin/bash

set -e

# Configuration
# Check if SQUEEZELITE_VERSION is provided, fail if not
if [ -z "${SQUEEZELITE_VERSION}" ]; then
    echo "ERROR: SQUEEZELITE_VERSION environment variable not set"
    echo "This variable must be set from build.sh"
    exit 1
fi

# Check if COMMIT_ID is provided, fail if not
if [ -z "${COMMIT_ID}" ]; then
    echo "ERROR: COMMIT_ID environment variable not set"
    echo "This variable must be set from build.sh"
    exit 1
fi

# Set required environment variables for dh_make
export USER=root
export LOGNAME=root
export DEBFULLNAME="HiFiBerry"
export DEBEMAIL="info@hifiberry.com"

PACKAGE_NAME="hifiberry-squeezelite"
MAINTAINER="HiFiBerry <info@hifiberry.com>"
WORK_DIR="/tmp/debian"
BUILD_DIR="${WORK_DIR}/${PACKAGE_NAME}-${SQUEEZELITE_VERSION}"
OUTPUT_DIR=${OUT_DIR:-/out}

# Ensure output directories exist
mkdir -p "$OUTPUT_DIR"
mkdir -p "$WORK_DIR"
mkdir -p "$BUILD_DIR"

cd "$WORK_DIR"

echo "===== Building Squeezelite ====="
echo "Cloning Squeezelite repository..."
git clone https://github.com/ralph-irving/squeezelite.git
cd squeezelite
git checkout "$COMMIT_ID"

echo "Compiling Squeezelite..."
make

# Create the package structure
echo "Creating package structure..."
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/lib/systemd/system"

# Copy binaries and scripts
echo "Copying binaries and scripts..."
cp squeezelite "$BUILD_DIR/usr/bin/"
cp /build/start-squeezelite "$BUILD_DIR/usr/bin/"
chmod +x "$BUILD_DIR/usr/bin/start-squeezelite"
cp /build/squeezelite.service "$BUILD_DIR/usr/lib/systemd/system/"

# Create control file
echo "Creating Debian control file..."
cat > "$BUILD_DIR/DEBIAN/control" << EOL
Package: $PACKAGE_NAME
Version: $SQUEEZELITE_VERSION
Architecture: arm64
Maintainer: $MAINTAINER
Priority: optional
Section: sound
Depends: libflac12, libmad0, libvorbis0a, libmpg123-0, libfaad2
Conflicts: squeezelite
Replaces: squeezelite
Provides: squeezelite
Description: Squeezelite - Lightweight Squeezebox player
 Squeezelite is a small headless squeezebox emulator for Linux.
 This package includes the Squeezelite binary and helper scripts.
EOL

# Create postinst script
echo "Creating postinst script..."
cat > "$BUILD_DIR/DEBIAN/postinst" << EOL
#!/bin/bash
set -e

# Create squeezelite user and group if they don't exist
if ! getent group squeezelite > /dev/null; then
    addgroup --quiet --system squeezelite
fi
if ! getent passwd squeezelite > /dev/null; then
    adduser --quiet --system --ingroup squeezelite --no-create-home --home /var/lib/squeezelite squeezelite
    usermod -a -G audio squeezelite
fi

# Create home directory for squeezelite if it doesn't exist
if [ ! -d /var/lib/squeezelite ]; then
    mkdir -p /var/lib/squeezelite
    chown squeezelite:squeezelite /var/lib/squeezelite
fi

# Enable the Squeezelite service
systemctl daemon-reload
systemctl enable squeezelite.service

#DEBHELPER#
exit 0
EOL
chmod +x "$BUILD_DIR/DEBIAN/postinst"

# Create prerm script
echo "Creating prerm script..."
cat > "$BUILD_DIR/DEBIAN/prerm" << EOL
#!/bin/bash
set -e

# Stop and disable the Squeezelite service on package removal
if [ "\$1" = "remove" ] || [ "\$1" = "purge" ]; then
    systemctl stop squeezelite.service || true
    systemctl disable squeezelite.service || true
fi

#DEBHELPER#
exit 0
EOL
chmod +x "$BUILD_DIR/DEBIAN/prerm"

# Create postrm script to clean up user account
echo "Creating postrm script..."
cat > "$BUILD_DIR/DEBIAN/postrm" << EOL
#!/bin/bash
set -e

if [ "\$1" = "purge" ]; then
    # Remove squeezelite user and group
    if getent passwd squeezelite > /dev/null; then
        deluser --quiet --system squeezelite || true
    fi
    if getent group squeezelite > /dev/null; then
        delgroup --quiet --system squeezelite || true
    fi
    
    # Remove home directory
    rm -rf /var/lib/squeezelite || true
fi

#DEBHELPER#
exit 0
EOL
chmod +x "$BUILD_DIR/DEBIAN/postrm"

# Build Debian package
echo "Building Debian package..."
PKG_NAME="${PACKAGE_NAME}_${SQUEEZELITE_VERSION}_arm64.deb"
dpkg-deb --build "$BUILD_DIR" "$OUTPUT_DIR/$PKG_NAME"

echo "Package build complete: $OUTPUT_DIR/$PKG_NAME"
#!/bin/bash
set -e

# ------------------------------
# Configuration
# ------------------------------
BUILD_DIR=$(pwd)

# Read version from version.txt if it exists, otherwise use VERSION environment variable
if [ -f "$BUILD_DIR/version.txt" ]; then
    VERSION=$(cat "$BUILD_DIR/version.txt")
else
    VERSION=${VERSION:-"1.0.0"}
fi

ARCH=$(dpkg --print-architecture)
VERSION_SUFFIX=${VERSION_SUFFIX:-}
# Form the complete package version
if [ -n "$VERSION_SUFFIX" ]; then
    PACKAGE_VERSION="${VERSION}.${VERSION_SUFFIX}"
else
    PACKAGE_VERSION="$VERSION"
fi

PACKAGE_NAME="hifiberry-raat"
OUTPUT_DIR=${OUT_DIR:-/out}
DEB_DIR="/tmp/debian-package/$PACKAGE_NAME"

# Update configure-raat script with the actual version
echo "Updating configure-raat with version $VERSION..."
sed -i "s/###MYVERSION###/echo $VERSION/g" "$BUILD_DIR/configure-raat"

# ------------------------------
# Build RAAT
# ------------------------------
echo "Building RAAT from pre-cloned repository..."
cd raat

echo "Compiling RAAT..."
./compile64

echo "Build complete. Creating package..."
cd "$BUILD_DIR"

# ------------------------------
# Package
# ------------------------------
# Clean previous package files
rm -rf "$DEB_DIR"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/lib/systemd/system"
mkdir -p "$DEB_DIR/usr/share/raat"

# Copy binaries to the package directory, excluding .a files
echo "Copying binaries to package directory..."
find raat/bin/release/linux/aarch64/ -type f ! -name '*.a' -exec cp {} "$DEB_DIR/usr/bin/" \;

# Copy systemd unit file
echo "Copying systemd unit file..."
cp raat.service "$DEB_DIR/usr/lib/systemd/system/"

# Copy the configure-raat script
echo "Copying configure-raat script..."
cp configure-raat "$DEB_DIR/usr/bin/"
chmod +x "$DEB_DIR/usr/bin/configure-raat"

# Create control file
cat > "$DEB_DIR/DEBIAN/control" << EOF
Package: $PACKAGE_NAME
Version: $PACKAGE_VERSION
Architecture: $ARCH
Maintainer: HiFiBerry <support@hifiberry.com>
Priority: optional
Section: sound
Depends: libglib2.0-0, libdbus-1-3, libdbus-glib-1-2
Description: RAAT binaries
 RAAT binaries for HiFiBerry audio solutions.
 Installed in /usr/bin.
EOF

# Create postinst script
cat > "$DEB_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e

# Create raat user if it doesn't exist
if ! id -u raat >/dev/null 2>&1; then
    adduser --system --group --no-create-home --quiet raat
fi

# Add raat user to audio and pipewire groups
usermod -a -G audio raat
if getent group pipewire >/dev/null; then
    usermod -a -G pipewire raat
fi

# Create directory for raat user
mkdir -p /var/lib/raat
chown raat:raat /var/lib/raat

# Create and set up config directory
mkdir -p /usr/share/raat
chown raat:raat /usr/share/raat

# Create /var/run/raat directory and set ownership to raat
mkdir -p /var/run/raat
chown raat:raat /var/run/raat
chmod 755 /var/run/raat

# Create UUID if it doesn't exist or is empty
if [ ! -f "/etc/uuid" ] || [ ! -s "/etc/uuid" ]; then
    echo "Creating new UUID"
    /usr/bin/uuid > /etc/uuid
    chmod 644 /etc/uuid
fi

# Make configure-raat executable
chmod +x /usr/bin/configure-raat

# Reload systemd configuration
if command -v systemctl >/dev/null; then
    systemctl daemon-reload
    systemctl enable raat.service
    systemctl start raat.service
fi
EOF
chmod +x "$DEB_DIR/DEBIAN/postinst"

# Create prerm script
cat > "$DEB_DIR/DEBIAN/prerm" << 'EOF'
#!/bin/bash
set -e

# Stop and disable systemd service
if command -v systemctl >/dev/null; then
    systemctl stop raat.service || true
    systemctl disable raat.service || true
fi
EOF
chmod +x "$DEB_DIR/DEBIAN/prerm"

# Build the package
echo "Building Debian package..."
dpkg-deb --build "$DEB_DIR" "$OUTPUT_DIR/${PACKAGE_NAME}_${PACKAGE_VERSION}_${ARCH}.deb"
echo "Debian package created at $OUTPUT_DIR/${PACKAGE_NAME}_${PACKAGE_VERSION}_${ARCH}.deb"
#!/bin/bash
set -e

# ------------------------------
# Configuration
# ------------------------------
PIPEWIRE_VERSION=${PIPEWIRE_VERSION:-1.4.2}
# Use version suffix provided or nothing if not provided
VERSION_SUFFIX=${VERSION_SUFFIX:-}
# Form the complete package version
if [ -n "$VERSION_SUFFIX" ]; then
    PACKAGE_VERSION="${PIPEWIRE_VERSION}.${VERSION_SUFFIX}"
else
    PACKAGE_VERSION="$PIPEWIRE_VERSION"
fi
INTERNAL_BUILD_DIR="/tmp/pipewire-build"
OUTPUT_DIR=${OUT_DIR:-/out}
INSTALL_PREFIX=${INSTALL_PREFIX:-/usr}
DEST_DIR="$INTERNAL_BUILD_DIR/pipewire-$PIPEWIRE_VERSION-staging"

# ------------------------------
# Prepare source
# ------------------------------
mkdir -p "$INTERNAL_BUILD_DIR"
cd "$INTERNAL_BUILD_DIR"

echo "Downloading PipeWire $PIPEWIRE_VERSION..."
curl -LO "https://gitlab.freedesktop.org/pipewire/pipewire/-/archive/$PIPEWIRE_VERSION/pipewire-$PIPEWIRE_VERSION.tar.gz"
tar xf "pipewire-$PIPEWIRE_VERSION.tar.gz"
cd "pipewire-$PIPEWIRE_VERSION"

# ------------------------------
# Build
# ------------------------------
echo "Configuring build with Meson and systemd system service..."
meson setup builddir --prefix=$INSTALL_PREFIX \
  -Dsystemd=enabled \
  -Dsystemd-system-service=enabled \
  -Dsystemd-user-service=disabled \
  -Dtest=disabled
  
echo "Building PipeWire..."
meson compile -C builddir

# ------------------------------
# Package
# ------------------------------
echo "Creating staging directory..."
mkdir -p "$DEST_DIR"

echo "Installing to staging directory..."
DESTDIR="$DEST_DIR" meson install -C builddir

# Remove files that conflict with libspa-0.2-dev package
echo "Removing files that conflict with libspa-0.2-dev package..."
rm -rf "$DEST_DIR$INSTALL_PREFIX/include/spa-0.2"
rm -f "$DEST_DIR$INSTALL_PREFIX/lib/aarch64-linux-gnu/pkgconfig/libspa-0.2.pc"

# Create postinst script to add pipewire user
echo "Creating postinst script..."
mkdir -p $INTERNAL_BUILD_DIR/debian/DEBIAN
cat > $INTERNAL_BUILD_DIR/debian/DEBIAN/postinst << EOF
#!/bin/sh
set -e

# Create pipewire system user and group if they don't exist
if ! getent group pipewire >/dev/null; then
    addgroup --quiet --system pipewire
fi
if ! getent passwd pipewire >/dev/null; then
    adduser --quiet --system --ingroup pipewire --no-create-home --home /nonexistent pipewire
    usermod -c "PipeWire System Daemon" pipewire
fi

# Add pipewire user to the audio group for access to audio devices
if getent group audio >/dev/null; then
    usermod -aG audio pipewire
fi

# Set proper permissions for pipewire directories
if [ -d /var/lib/pipewire ]; then
    chown -R pipewire:pipewire /var/lib/pipewire
fi

# Handle asound.conf file
if [ -f /etc/asound.conf ] && [ ! -L /etc/asound.conf ]; then
    # Backup existing asound.conf if it's a regular file (not a symlink)
    mv /etc/asound.conf /etc/asound.conf.bak
    echo "Backed up existing /etc/asound.conf to /etc/asound.conf.bak"
elif [ -L /etc/asound.conf ]; then
    # Remove existing symlink
    rm -f /etc/asound.conf
fi

# Create symlink from PipeWire asound.conf
ln -sf /etc/asound.conf.pipewire /etc/asound.conf

# Copy ALSA configuration for PipeWire
mkdir -p /etc/alsa/conf.d
if [ -f /usr/share/alsa/alsa.conf.d/50-pipewire.conf ]; then
    cp -f /usr/share/alsa/alsa.conf.d/50-pipewire.conf /etc/alsa/conf.d/
fi

# Reload systemd to pick up changes
if command -v systemctl >/dev/null; then
    systemctl daemon-reload || true
    
    # Enable and start pipewire service
    if systemctl --all --type=service | grep -q pipewire.service; then
        systemctl enable pipewire.service || true
        systemctl start pipewire.service || true
    fi
    
    # Enable and start wireplumber service
    if [ -f /etc/systemd/system/wireplumber-system.service ]; then
        systemctl enable wireplumber-system.service || true
        systemctl start wireplumber-system.service || true
    fi
fi

exit 0
EOF
chmod 755 $INTERNAL_BUILD_DIR/debian/DEBIAN/postinst

# Create installation script without user creation (that's only in postinst now)
echo "Creating installation script..."
cat > /tmp/install-pipewire.sh << EOF
#!/bin/bash
set -e

# Copy files from staging directory to system
cp -r $DEST_DIR$INSTALL_PREFIX/* $INSTALL_PREFIX/

# Create directory for pipewire runtime files if needed
mkdir -p /var/lib/pipewire
EOF
chmod +x /tmp/install-pipewire.sh

echo "Packaging PipeWire using checkinstall..."
cd "$INTERNAL_BUILD_DIR/pipewire-$PIPEWIRE_VERSION"

echo "Creating full package with manual control files..."
# Instead of relying on checkinstall's --include parameter, we'll create a complete package structure
WORK_DIR=/tmp/debian-package
PKG_NAME=hifiberry-pipewire
ARCH=$(dpkg --print-architecture)

# Clean previous attempts
rm -rf $WORK_DIR
mkdir -p $WORK_DIR/$PKG_NAME/DEBIAN
mkdir -p $WORK_DIR/$PKG_NAME/usr
mkdir -p $WORK_DIR/$PKG_NAME/etc/systemd/system
mkdir -p $WORK_DIR/$PKG_NAME/etc

# Copy control files
cp $INTERNAL_BUILD_DIR/debian/DEBIAN/postinst $WORK_DIR/$PKG_NAME/DEBIAN/

# Create asound.conf for PipeWire
cat > $WORK_DIR/$PKG_NAME/etc/asound.conf.pipewire << EOF
# PipeWire ALSA configuration
# Use PipeWire by default
pcm.!default {
    type pipewire
    playback_node "-1"
    capture_node  "-1"
    hint {
        show on
        description "Default ALSA Output (currently PipeWire Media Server)"
    }
}

ctl.!default {
    type pipewire
}
EOF

# Create prerm script to handle removal/upgrade
cat > $INTERNAL_BUILD_DIR/debian/DEBIAN/prerm << EOF
#!/bin/sh
set -e

# If we're removing the package (not upgrading), restore the original asound.conf if it exists
if [ "\$1" = "remove" ]; then
    # Check if we have a symlink and a backup
    if [ -L /etc/asound.conf ] && [ -f /etc/asound.conf.bak ]; then
        # Remove the symlink
        rm -f /etc/asound.conf
        # Restore the original
        mv /etc/asound.conf.bak /etc/asound.conf
        echo "Restored original ALSA configuration."
    elif [ -L /etc/asound.conf ]; then
        # Just remove the symlink if there's no backup
        rm -f /etc/asound.conf
    fi

    # Stop services before removal
    if command -v systemctl >/dev/null; then
        systemctl stop wireplumber-system.service 2>/dev/null || true
        systemctl stop pipewire.service 2>/dev/null || true
        systemctl disable wireplumber-system.service 2>/dev/null || true
        systemctl disable pipewire.service 2>/dev/null || true
    fi
fi

exit 0
EOF
chmod 755 $INTERNAL_BUILD_DIR/debian/DEBIAN/prerm

# Copy prerm script to the package
cp $INTERNAL_BUILD_DIR/debian/DEBIAN/prerm $WORK_DIR/$PKG_NAME/DEBIAN/

# Copy wireplumber service file to systemd directory
if [ -f /build/wireplumber-system.service ]; then
  cp /build/wireplumber-system.service $WORK_DIR/$PKG_NAME/etc/systemd/system/
fi

# Create control file
cat > $WORK_DIR/$PKG_NAME/DEBIAN/control << EOF
Package: hifiberry-pipewire
Version: $PACKAGE_VERSION
Section: sound
Priority: optional
Architecture: $ARCH
Provides: hifiberry-pipewire
Conflicts: pipewire, libpipewire-0.3-0, libpipewire-0.3-common, libpipewire-0.3-modules
Replaces: pipewire
Maintainer: HiFiBerry <support@hifiberry.com>
Description: PipeWire system for HiFiBerry OS
 PipeWire is a server and API to handle multimedia pipelines.
EOF

# Copy installation files
cp -r $DEST_DIR$INSTALL_PREFIX/* $WORK_DIR/$PKG_NAME/usr/

# Modify pipewire.conf to allow more sample rates
PIPEWIRE_CONF_DIR=$WORK_DIR/$PKG_NAME/usr/share/pipewire
if [ -d "$PIPEWIRE_CONF_DIR" ] && [ -f "$PIPEWIRE_CONF_DIR/pipewire.conf" ]; then
  echo "Modifying pipewire.conf to allow more sample rates..."
  # Create backup just in case
  cp "$PIPEWIRE_CONF_DIR/pipewire.conf" "$PIPEWIRE_CONF_DIR/pipewire.conf.orig"
  # Replace the commented default.clock.allowed-rates line with our expanded rates
  sed -i 's|#default.clock.allowed-rates = \[ 48000 \]|default.clock.allowed-rates = \[ 44100 48000 88200 96000 176400 192000 \]|g' "$PIPEWIRE_CONF_DIR/pipewire.conf"
fi

# Create the package
dpkg-deb --build $WORK_DIR/$PKG_NAME $OUTPUT_DIR

echo "Build complete. .deb package is in $OUTPUT_DIR/"


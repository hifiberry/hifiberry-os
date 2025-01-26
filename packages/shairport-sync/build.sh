#!/bin/bash

set -e

# Configuration
VERSION="4.3.5"
PACKAGE_NAME="shairport-sync"
MAINTAINER="HiFiBerry <support@hifiberry.com>"
SOURCE_URL="https://github.com/mikebrady/shairport-sync/archive/refs/tags/${VERSION}.tar.gz"
WORK_DIR="$HOME/src/debian"
BUILD_DIR="${WORK_DIR}/${PACKAGE_NAME}-${VERSION}"
OUTPUT_DIR="$HOME/packages"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Functions
function clean() {
    echo "Cleaning up..."
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

function install_dependencies() {
    echo "Installing necessary build tools and dependencies..."
    sudo apt-get update
    sudo apt-get install -y build-essential devscripts fakeroot dh-make \
        libssl-dev libavahi-client-dev libpopt-dev libconfig-dev \
        libdaemon-dev libsoxr-dev avahi-daemon xxd libplist-dev \
        libsodium-dev libgcrypt-dev libavutil-dev libavcodec-dev \
        libavformat-dev uuid-dev || {
            echo "Error: Unable to install one or more dependencies."
            exit 1
        }
}

function create_package() {
    echo "Preparing working directory..."
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"

    echo "Downloading source code..."
    wget "$SOURCE_URL" -O "${PACKAGE_NAME}-${VERSION}.tar.gz"
    tar -xzf "${PACKAGE_NAME}-${VERSION}.tar.gz"

    cd "$BUILD_DIR"

    echo "Cleaning up any existing debian directory..."
    rm -rf debian

    echo "Initializing Debian packaging files..."
    dh_make --createorig -s -y --packagename "${PACKAGE_NAME}_${VERSION}"

    echo "Updating debian/control file..."
    cat > debian/control <<EOL
Source: $PACKAGE_NAME
Section: sound
Priority: optional
Maintainer: $MAINTAINER
Build-Depends: debhelper-compat (= 13), libssl-dev, libavahi-client-dev, libpopt-dev, libconfig-dev, libdaemon-dev, libsoxr-dev, avahi-daemon, libplist-dev, libsodium-dev, libgcrypt-dev, libavutil-dev, libavcodec-dev, libavformat-dev, uuid-dev
Standards-Version: 4.5.0
Homepage: https://github.com/mikebrady/shairport-sync

Package: $PACKAGE_NAME
Architecture: any
Depends: ${shlibs:Depends}, ${misc:Depends}, libssl3, libavahi-client3, libpopt0, libconfig9, libdaemon0, libsoxr0, avahi-daemon, libplist3, libsodium23, libgcrypt20, libavutil-dev, libavcodec-dev, libavformat-dev, uuid-dev
Description: AirPlay audio player
 A multi-room synchronized audio player for AirPlay devices.
EOL

    echo "Updating debian/rules file..."
    cat > debian/rules <<'EOL'
#!/usr/bin/make -f
%:
	dh $@

override_dh_auto_configure:
	./configure --prefix=/usr --sysconfdir=/etc --with-airplay-2 --with-ssl=openssl --with-systemd --with-avahi --with-alsa --with-soxr --with-pipe --with-stdout --with-metadata

override_dh_auto_install:
	sed -i '/getent group/d' Makefile
	sed -i '/getent passwd/d' Makefile
	sed -i '/cp \.\/scripts\/shairport-sync\.conf/d' Makefile
	make install DESTDIR=$(CURDIR)/debian/$(shell dh_listpackages) AM_UPDATE_INFO_DIR=no
	echo "Expected paths for installed files:"
	echo $(CURDIR)/debian/$(shell dh_listpackages)
	find $(CURDIR)/debian/$(shell dh_listpackages) -type f
EOL
    chmod +x debian/rules

    echo "Creating postinst script for user and group creation..."
    cat > debian/postinst <<EOL
#!/bin/bash
set -e

# Create group if it doesn't exist
if ! getent group shairport-sync > /dev/null; then
    groupadd -r shairport-sync
fi

# Create user if it doesn't exist
if ! getent passwd shairport-sync > /dev/null; then
    useradd -r -M -g shairport-sync -s /usr/sbin/nologin -G audio shairport-sync
fi

#DEBHELPER#
EOL
    chmod +x debian/postinst

    echo "Building the Debian package..."
    debuild -us -uc

    echo "Moving the package to $OUTPUT_DIR..."
    PKG_NAME="${PACKAGE_NAME}_${VERSION}-1_$(dpkg-architecture -qDEB_BUILD_ARCH).deb"
    mv "../${PKG_NAME}" "$OUTPUT_DIR/"
    echo "Package created: $OUTPUT_DIR/${PKG_NAME}"
}

function install_package() {
    echo "Installing dependencies..."
    install_dependencies
    echo "Creating the package..."
    create_package
    echo "Installing the package..."
    sudo dpkg -i "$OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}-1_$(dpkg-architecture -qDEB_BUILD_ARCH).deb"
    echo "Installation complete!"
}

# Main logic
case "$1" in
    --clean)
        clean
        ;;
    --install)
        install_package
        ;;
    *)
        create_package
        ;;
esac


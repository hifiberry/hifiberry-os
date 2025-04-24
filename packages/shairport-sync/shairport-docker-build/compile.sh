#!/bin/bash

set -e

# Configuration
# Check if SHAIRPORT_VERSION is provided, fail if not
if [ -z "${SHAIRPORT_VERSION}" ]; then
    echo "ERROR: SHAIRPORT_VERSION environment variable not set"
    echo "This variable must be set from build.sh"
    exit 1
fi

# Check if PACKAGE_VERSION is provided, use SHAIRPORT_VERSION if not
if [ -z "${PACKAGE_VERSION}" ]; then
    echo "PACKAGE_VERSION not set, using SHAIRPORT_VERSION"
    PACKAGE_VERSION="${SHAIRPORT_VERSION}"
fi

# Set required environment variables for dh_make
export USER=root
export LOGNAME=root
export DEBFULLNAME="HiFiBerry"
export DEBEMAIL="support@hifiberry.com"

PACKAGE_NAME="hifiberry-shairport"
SOURCE_PACKAGE_NAME="shairport-sync"
MAINTAINER="HiFiBerry <support@hifiberry.com>"
SOURCE_URL="https://github.com/mikebrady/shairport-sync/archive/refs/tags/${SHAIRPORT_VERSION}.tar.gz"
NQPTP_VERSION="1.2.4"
NQPTP_URL="https://github.com/mikebrady/nqptp.git"
METADATA_READER_URL="https://github.com/mikebrady/shairport-sync-metadata-reader.git"
WORK_DIR="/tmp/debian"
BUILD_DIR="${WORK_DIR}/${SOURCE_PACKAGE_NAME}-${SHAIRPORT_VERSION}"
NQPTP_DIR="${WORK_DIR}/nqptp"
METADATA_READER_DIR="${WORK_DIR}/metadata-reader"
OUTPUT_DIR=${OUT_DIR:-/out}

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Build NQPTP first
echo "===== Building NQPTP ====="
echo "Cloning NQPTP repository..."
mkdir -p "$NQPTP_DIR"
git clone "$NQPTP_URL" "$NQPTP_DIR"
cd "$NQPTP_DIR"

echo "Checking out NQPTP ${NQPTP_VERSION}..."
git checkout "$NQPTP_VERSION"

echo "Building NQPTP..."
autoreconf -fi
./configure --with-systemd-startup
make

# Build metadata reader
echo "===== Building Shairport Sync Metadata Reader ====="
echo "Cloning Metadata Reader repository..."
mkdir -p "$METADATA_READER_DIR"
git clone "$METADATA_READER_URL" "$METADATA_READER_DIR"
cd "$METADATA_READER_DIR"

echo "Building Metadata Reader..."
if [ -f "autogen.sh" ]; then
  ./autogen.sh
else
  autoreconf -fi
fi
./configure
make

echo "===== Building Shairport Sync ====="
echo "Preparing working directory..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "Downloading source code..."
wget "$SOURCE_URL" -O "${SOURCE_PACKAGE_NAME}-${SHAIRPORT_VERSION}.tar.gz"
tar -xzf "${SOURCE_PACKAGE_NAME}-${SHAIRPORT_VERSION}.tar.gz"

cd "$BUILD_DIR"

echo "Cleaning up any existing debian directory..."
rm -rf debian

echo "Initializing Debian packaging files..."
dh_make --createorig -s -y --packagename "${PACKAGE_NAME}_${PACKAGE_VERSION}"

echo "Updating debian/control file..."
cat > debian/control <<EOL
Source: $PACKAGE_NAME
Section: sound
Priority: optional
Maintainer: $MAINTAINER
Build-Depends: debhelper-compat (= 13), libssl-dev, libavahi-client-dev, libpopt-dev, libconfig-dev, libdaemon-dev, libsoxr-dev, avahi-daemon, libplist-dev, libsodium-dev, libgcrypt-dev, libavutil-dev, libavcodec-dev, libavformat-dev, uuid-dev, libsystemd-dev, libglib2.0-dev, libmosquitto-dev
Standards-Version: 4.5.0
Homepage: https://github.com/mikebrady/shairport-sync

Package: $PACKAGE_NAME
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}, libssl3, libavahi-client3, libpopt0, libconfig9, libdaemon0, libsoxr0, avahi-daemon, libplist3, libsodium23, libgcrypt20, libavutil-dev, libavcodec-dev, libavformat-dev, uuid-dev, libsystemd0, libcap2-bin, libglib2.0-0, libmosquitto1
Provides: shairport-sync, nqptp
Conflicts: shairport-sync, nqptp
Replaces: shairport-sync, nqptp
Description: HiFiBerry AirPlay audio player with NQPTP
 A multi-room synchronized audio player for AirPlay devices,
 customized for HiFiBerry devices. Includes NQPTP daemon for
 network clock synchronization required by AirPlay 2.
EOL

echo "Updating debian/rules file..."
cat > debian/rules <<'EOL'
#!/usr/bin/make -f
%:
	dh $@

override_dh_auto_configure:
	./configure --prefix=/usr --sysconfdir=/etc --with-airplay-2 --with-ssl=openssl --with-mqtt-client --with-dbus-interface --with-mpris-interface --with-systemd --with-avahi --with-alsa --with-soxr --with-pipe --with-stdout --with-metadata

override_dh_auto_install:
	sed -i '/getent group/d' Makefile
	sed -i '/getent passwd/d' Makefile
	sed -i '/cp \.\/scripts\/shairport-sync\.conf/d' Makefile
	make install DESTDIR=$(CURDIR)/debian/$(shell dh_listpackages) AM_UPDATE_INFO_DIR=no
	
	# Install systemd service files
	install -D -m 644 /build/systemd/shairport.service $(CURDIR)/debian/$(shell dh_listpackages)/lib/systemd/system/shairport.service
	install -D -m 644 /build/systemd/nqptp.service $(CURDIR)/debian/$(shell dh_listpackages)/lib/systemd/system/nqptp.service
	
	# Install NQPTP binary and man page
	install -D -m 755 /tmp/debian/nqptp/nqptp $(CURDIR)/debian/$(shell dh_listpackages)/usr/bin/nqptp
	mkdir -p $(CURDIR)/debian/$(shell dh_listpackages)/usr/share/man/man1/
	if [ -f "/tmp/debian/nqptp/nqptp.1" ]; then \
		install -D -m 644 /tmp/debian/nqptp/nqptp.1 $(CURDIR)/debian/$(shell dh_listpackages)/usr/share/man/man1/nqptp.1; \
	fi
	
	# Install metadata reader
	install -D -m 755 /tmp/debian/metadata-reader/shairport-sync-metadata-reader $(CURDIR)/debian/$(shell dh_listpackages)/usr/bin/shairport-sync-metadata-reader
	
	# Install our custom scripts
	install -D -m 755 /build/start-shairport.sh $(CURDIR)/debian/$(shell dh_listpackages)/usr/bin/start-shairport.sh
	install -D -m 755 /build/shairport-event.sh $(CURDIR)/debian/$(shell dh_listpackages)/usr/bin/shairport-event.sh
	install -D -m 755 /build/shairport-metadata-example.sh $(CURDIR)/debian/$(shell dh_listpackages)/usr/bin/shairport-metadata-example.sh
	
	# Install default configuration file
	install -D -m 644 /build/shairport-sync.conf.default $(CURDIR)/debian/$(shell dh_listpackages)/etc/shairport-sync.conf.default
	
	# Create symlinks for start and stop scripts
	mkdir -p $(CURDIR)/debian/$(shell dh_listpackages)/usr/bin/
	ln -sf /usr/bin/shairport-event.sh $(CURDIR)/debian/$(shell dh_listpackages)/usr/bin/shairport-start
	ln -sf /usr/bin/shairport-event.sh $(CURDIR)/debian/$(shell dh_listpackages)/usr/bin/shairport-stop
	
	echo "Expected paths for installed files:"
	echo $(CURDIR)/debian/$(shell dh_listpackages)
	find $(CURDIR)/debian/$(shell dh_listpackages) -type f
EOL
chmod +x debian/rules

echo "Creating postinst script for user and group creation..."
cat > debian/postinst <<EOL
#!/bin/bash
set -e

# Create shairport-sync group if it doesn't exist
if ! getent group shairport-sync > /dev/null; then
    groupadd -r shairport-sync
fi

# Create shairport-sync user if it doesn't exist
if ! getent passwd shairport-sync > /dev/null; then
    useradd -r -M -g shairport-sync -s /usr/sbin/nologin -G audio shairport-sync
fi

# Create nqptp group if it doesn't exist
if ! getent group nqptp > /dev/null; then
    groupadd -r nqptp
fi

# Create nqptp user if it doesn't exist
if ! getent passwd nqptp > /dev/null; then
    useradd -r -M -g nqptp -s /usr/sbin/nologin nqptp
fi

# Add shairport-sync user to pipewire group for PipeWire integration
if getent group pipewire > /dev/null; then
    usermod -a -G pipewire shairport-sync || true
fi

# Set capabilities for nqptp
if command -v setcap > /dev/null; then
    setcap 'cap_net_bind_service=+ep' /usr/bin/nqptp || true
fi

# Check if /etc/shairport-sync.conf exists, if not copy the default configuration
if [ ! -f /etc/shairport-sync.conf ] && [ -f /etc/shairport-sync.conf.default ]; then
    echo "No configuration file found. Installing default configuration."
    cp /etc/shairport-sync.conf.default /etc/shairport-sync.conf
    chown root:root /etc/shairport-sync.conf
    chmod 644 /etc/shairport-sync.conf
fi

# Enable and start systemd services
if [ -x /bin/systemctl ] || [ -x /usr/bin/systemctl ]; then
    systemctl daemon-reload || true
    
    # Enable and start nqptp service first
    systemctl enable nqptp.service || true
    systemctl start nqptp.service || true
    
    # Enable and start shairport service
    systemctl enable shairport.service || true
    systemctl start shairport.service || true
fi

#DEBHELPER#
EOL
chmod +x debian/postinst

# Also create a prerm script to handle service during package removal
cat > debian/prerm <<EOL
#!/bin/bash
set -e

# Stop and disable systemd service on package removal
if [ "\$1" = "remove" ] || [ "\$1" = "purge" ]; then
    if [ -x /bin/systemctl ] || [ -x /usr/bin/systemctl ]; then
        systemctl stop shairport.service || true
        systemctl disable shairport.service || true
        systemctl stop nqptp.service || true
        systemctl disable nqptp.service || true
    fi
fi

#DEBHELPER#
EOL
chmod +x debian/prerm

echo "Building the Debian package..."
debuild -us -uc

echo "Moving the package to $OUTPUT_DIR..."
cd "$WORK_DIR"
PKG_NAME="${PACKAGE_NAME}_${PACKAGE_VERSION}-1_$(dpkg-architecture -qDEB_BUILD_ARCH).deb"
mv "${PKG_NAME}" "$OUTPUT_DIR/"
echo "Package created: $OUTPUT_DIR/${PKG_NAME}"
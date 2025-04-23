#!/bin/bash

set -e

# Configuration
# Check if MPD_VERSION is provided, fail if not
if [ -z "${MPD_VERSION}" ]; then
    echo "ERROR: MPD_VERSION environment variable not set"
    echo "This variable must be set from build.sh"
    exit 1
fi

# Set required environment variables for dh_make
export USER=root
export LOGNAME=root
export DEBFULLNAME="HiFiBerry"
export DEBEMAIL="support@hifiberry.com"

PACKAGE_NAME="hifiberry-mpd"
SOURCE_PACKAGE_NAME="mpd"
MAINTAINER="HiFiBerry <support@hifiberry.com>"
SOURCE_URL="https://github.com/MusicPlayerDaemon/MPD/archive/refs/tags/v${MPD_VERSION}.tar.gz"
MPC_URL="https://github.com/MusicPlayerDaemon/mpc/archive/refs/tags/v${MPC_VERSION}.tar.gz"
WORK_DIR="/tmp/debian"
BUILD_DIR="${WORK_DIR}/${SOURCE_PACKAGE_NAME}-${MPD_VERSION}"
MPC_BUILD_DIR="${WORK_DIR}/mpc-${MPC_VERSION}"
MPC_INSTALL_DIR="${WORK_DIR}/mpc-install"
OUTPUT_DIR=${OUT_DIR:-/out}

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

echo "Preparing working directory..."
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Download and build MPC
echo "Building MPC ${MPC_VERSION}..."
wget "$MPC_URL" -O "mpc-${MPC_VERSION}.tar.gz"
tar -xzf "mpc-${MPC_VERSION}.tar.gz"
cd "${MPC_BUILD_DIR}"

# Build MPC
mkdir -p build
cd build
meson setup --prefix="${MPC_INSTALL_DIR}" --buildtype=release ..
ninja
ninja install

echo "Downloading MPD ${MPD_VERSION} source code..."
cd "$WORK_DIR"
wget "$SOURCE_URL" -O "${SOURCE_PACKAGE_NAME}-${MPD_VERSION}.tar.gz"
tar -xzf "${SOURCE_PACKAGE_NAME}-${MPD_VERSION}.tar.gz"
mv "MPD-${MPD_VERSION}" "${SOURCE_PACKAGE_NAME}-${MPD_VERSION}"

cd "$BUILD_DIR"

echo "Cleaning up any existing debian directory..."
rm -rf debian

echo "Initializing Debian packaging files..."
dh_make --createorig -s -y --packagename "${PACKAGE_NAME}_${MPD_VERSION}"

echo "Updating debian/control file..."
cat > debian/control <<EOL
Source: $PACKAGE_NAME
Section: sound
Priority: optional
Maintainer: $MAINTAINER
Build-Depends: debhelper-compat (= 13), meson, 
 libavcodec-dev, libavformat-dev, libavutil-dev, libboost-dev, 
 libasound2-dev, libflac-dev, libid3tag0-dev, libmad0-dev, 
 libmikmod-dev, libpcre2-dev, libsndfile1-dev, libsoxr-dev, 
 libvorbis-dev, libopus-dev, libsystemd-dev, python3-sphinx,
 libsqlite3-dev, libcurl4-openssl-dev, libyajl-dev, libgcrypt20-dev,
 libfmt-dev, libexpat1-dev, libavahi-client-dev
Standards-Version: 4.5.0
Homepage: https://www.musicpd.org/
Rules-Requires-Root: no

Package: $PACKAGE_NAME
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}
Provides: mpd
Conflicts: mpd
Replaces: mpd
Description: HiFiBerry Music Player Daemon
 MPD is a daemon for playing music files. Music is played through the
 configured audio outputs. The daemon can be controlled from the command
 line or through its network protocol.
 .
 This custom package is optimized for HiFiBerry devices.
EOL

echo "Updating debian/rules file..."
cat > debian/rules <<'EOL'
#!/usr/bin/make -f
%:
	dh $@

override_dh_auto_configure:
	dh_auto_configure -- -Dalsa=enabled -Dsystemd=enabled -Dtest=false \
	-Dlocal_socket=true -Dcue=true -Dzeroconf=avahi -Dpulse=disabled -Djack=disabled

override_dh_auto_install:
	DESTDIR=$(CURDIR)/debian/$(shell dh_listpackages) dh_auto_install
	
	# Remove the automatically installed service files
	rm -f $(CURDIR)/debian/$(shell dh_listpackages)/usr/lib/systemd/system/mpd.service
	rm -f $(CURDIR)/debian/$(shell dh_listpackages)/usr/lib/systemd/user/mpd.service
	
	# Create systemd directories
	mkdir -p $(CURDIR)/debian/$(shell dh_listpackages)/lib/systemd/system
	
	# Install our custom systemd service file
	install -D -m 644 /build/systemd/mpd.service \
		$(CURDIR)/debian/$(shell dh_listpackages)/lib/systemd/system/mpd.service
	
	# Install default configuration file
	install -D -m 644 /build/config/mpd.conf.default \
		$(CURDIR)/debian/$(shell dh_listpackages)/etc/mpd.conf.default
	
	# Create directories
	mkdir -p $(CURDIR)/debian/$(shell dh_listpackages)/var/lib/mpd
	mkdir -p $(CURDIR)/debian/$(shell dh_listpackages)/var/lib/mpd/music
	mkdir -p $(CURDIR)/debian/$(shell dh_listpackages)/var/lib/mpd/playlists
	
	# Install MPC binary
	install -D -m 755 /tmp/debian/mpc-install/bin/mpc \
		$(CURDIR)/debian/$(shell dh_listpackages)/usr/bin/mpc
		
	# Also install the man page
	install -D -m 644 /tmp/debian/mpc-install/share/man/man1/mpc.1 \
		$(CURDIR)/debian/$(shell dh_listpackages)/usr/share/man/man1/mpc.1
EOL
chmod +x debian/rules

echo "Creating postinst script for user creation..."
cat > debian/postinst <<EOL
#!/bin/bash
set -e

# Create group if it doesn't exist
if ! getent group mpd > /dev/null; then
    groupadd -r mpd
fi

# Create user if it doesn't exist
if ! getent passwd mpd > /dev/null; then
    useradd -r -M -g mpd -G audio,pipewire -s /usr/sbin/nologin mpd
else
    # User already exists, ensure it belongs to the right groups
    usermod -a -G audio,pipewire mpd
fi

# Ensure MPD owns its directories
chown -R mpd:mpd /var/lib/mpd

# Copy default config file if the config doesn't exist
if [ ! -f /etc/mpd.conf ]; then
    cp /etc/mpd.conf.default /etc/mpd.conf
    chmod 644 /etc/mpd.conf
fi

# Enable and start systemd service
if [ -x /bin/systemctl ] || [ -x /usr/bin/systemctl ]; then
    systemctl daemon-reload || true
    systemctl enable mpd.service || true
    systemctl restart mpd.service || true
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
        systemctl stop mpd.service || true
        systemctl disable mpd.service || true
    fi
fi

#DEBHELPER#
EOL
chmod +x debian/prerm

echo "Building the Debian package..."
debuild -us -uc

echo "Moving the package to $OUTPUT_DIR..."
cd "$WORK_DIR"
PKG_NAME="${PACKAGE_NAME}_${MPD_VERSION}-1_$(dpkg-architecture -qDEB_BUILD_ARCH).deb"
mv "${PKG_NAME}" "$OUTPUT_DIR/"
echo "Package created: $OUTPUT_DIR/${PKG_NAME}"
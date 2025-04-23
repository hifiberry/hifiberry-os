#!/bin/bash

set -e

# Configuration
VERSION="1.2.4"
PACKAGE_NAME="nqptp"
MAINTAINER="HiFiBerry <support@hifiberry.com>"
GIT_URL="https://github.com/mikebrady/nqptp.git"
WORK_DIR="$HOME/src/debian"
BUILD_DIR="${WORK_DIR}/${PACKAGE_NAME}"
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
        autoconf automake libtool libsystemd-dev || {
            echo "Error: Unable to install one or more dependencies."
            exit 1
        }
}

function install_build_deps() {
    echo "Installing build dependencies from debian/control..."
    sudo apt-get update
    sudo apt-get build-dep -y .
}

function create_package() {
    echo "Preparing working directory..."
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"

    echo "Cloning repository..."
    git clone "$GIT_URL" "$BUILD_DIR"
    cd "$BUILD_DIR"

    echo "Checking out the specified tag..."
    git checkout "$VERSION"

    echo "Replacing problematic commands with echo..."
    sed -i 's/setcap/echo "Skipping setcap"/g' Makefile.am || echo "setcap not found in Makefile.am."
    sed -i 's/groupadd/echo "Skipping groupadd"/g' Makefile.am || echo "groupadd not found in Makefile.am."
    sed -i 's/useradd/echo "Skipping useradd"/g' Makefile.am || echo "useradd not found in Makefile.am."

    echo "Rebuilding autotools files..."
    autoreconf -fi

    echo "Running configure script..."
    ./configure --with-systemd-startup

    echo "Building the project..."
    make

    echo "Cleaning up any existing debian directory..."
    rm -rf debian

    echo "Initializing Debian packaging files..."
    dh_make --createorig -s -y --packagename "${PACKAGE_NAME}_${VERSION}"

    echo "Updating debian/control file..."
    cat > debian/control <<EOL
Source: $PACKAGE_NAME
Section: net
Priority: optional
Maintainer: $MAINTAINER
Build-Depends: debhelper-compat (= 13), autoconf, automake, libtool, libsystemd-dev
Standards-Version: 4.5.0
Homepage: https://github.com/mikebrady/nqptp

Package: $PACKAGE_NAME
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}, libsystemd0, libcap2-bin
Description: Network clock synchronization
 nqptp is a network clock synchronization daemon used with Shairport Sync.
EOL

    echo "Updating debian/rules file..."
    echo "CURDIR: $(pwd)"
    cat > debian/rules <<'EOL'
#!/usr/bin/make -f
%:
	dh $@

override_dh_auto_install:
	dh_auto_install --destdir=$(CURDIR)/debian/$(shell dh_listpackages)
EOL
    chmod +x debian/rules

    echo "Creating postinst script for setting capabilities and user..."
    cat > debian/postinst <<EOL
#!/bin/bash
set -e

# Add nqptp group if it doesn't exist
if ! getent group nqptp >/dev/null; then
    groupadd -r nqptp
fi

# Add nqptp user if it doesn't exist
if ! getent passwd nqptp >/dev/null; then
    useradd -r -M -g nqptp -s /usr/sbin/nologin nqptp
fi

# Set the required capabilities for the nqptp binary
if command -v setcap > /dev/null; then
    setcap 'cap_net_bind_service=+ep' /usr/bin/nqptp || true
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
        install_dependencies
        create_package
        ;;
esac



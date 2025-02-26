#!/bin/bash
# build_deb_from_github.sh
# This script clones (or updates) the pyedbglib repository from GitHub,
# creates the necessary debian/ packaging files for a package that simply copies
# the pyedbglib source directory into Python’s site-packages,
# builds the .deb package, and then copies the resulting .deb package to ~/packages.
#
# The package will install the pyedbglib module into:
#   /usr/lib/python3/dist-packages/pyedbglib

set -e

# Variables (adjust these as needed)
REPO_URL="https://github.com/microchip-pic-avr-tools/pyedbglib.git"
REPO_DIR="pyedbglib"
PACKAGE_NAME="python3-pyedbglib"
# Upstream version 2.24.2 with a Debian revision of -1
VERSION="2.24.2-2"
DISTRIBUTION="bookworm"
URGENCY="low"
MAINTAINER="HiFiBerry <support@hifiberry.com>"
HOMEPAGE="https://github.com/microchip-pic-avr-tools/pyedbglib"
DESCRIPTION="Python library for EDBG communications
 This package provides a library and utilities for communicating with EDBG devices."

# Clone the repository if it doesn't exist; otherwise, update it.
if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning repository from $REPO_URL..."
    git clone "$REPO_URL" "$REPO_DIR"
else
    echo "Repository already exists. Updating..."
    cd "$REPO_DIR"
    git pull
    cd ..
fi

# Change into the repository directory
cd "$REPO_DIR"

echo "Creating debian packaging files..."

# Create debian directory if it doesn't exist
mkdir -p debian

# 1. Create debian/control
cat <<EOF > debian/control
Source: ${PACKAGE_NAME}
Section: python
Priority: optional
Maintainer: ${MAINTAINER}
Build-Depends: debhelper (>= 11)
Standards-Version: 4.5.0
Homepage: ${HOMEPAGE}

Package: ${PACKAGE_NAME}
Architecture: all
Depends: \${misc:Depends}
Description: Python library for EDBG communications
 ${DESCRIPTION}
EOF

# 2. Create debian/changelog
if command -v dch >/dev/null 2>&1; then
  dch --create --package ${PACKAGE_NAME} --newversion "${VERSION}" --distribution "${DISTRIBUTION}" --urgency "${URGENCY}" "Initial release." --force-distribution
else
  DATE=$(date -R)
  cat <<EOF > debian/changelog
${PACKAGE_NAME} (${VERSION}) ${DISTRIBUTION}; urgency=${URGENCY}

  * Initial release.

 -- ${MAINTAINER}  ${DATE}
EOF
fi

# 3. Create debian/rules (minimal rules file)
cat <<'EOF' > debian/rules
#!/usr/bin/make -f
%:
	dh $@
EOF
chmod +x debian/rules

# 4. Create debian/compat (set debhelper compatibility level)
echo "11" > debian/compat

# 5. Create debian/install
# This file tells dpkg-buildpackage to copy the entire "pyedbglib" directory
# to /usr/lib/python3/dist-packages/ in the final package.
cat <<EOF > debian/install
pyedbglib usr/lib/python3/dist-packages/
EOF

# 6. Create debian/copyright
cat <<EOF > debian/copyright
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${PACKAGE_NAME}
Source: ${HOMEPAGE}

Files: *
Copyright: 2025 ${MAINTAINER}
License: MIT
EOF

# 7. Optionally, create debian/README.Debian
cat <<EOF > debian/README.Debian
This package was created using an automated packaging script.
It installs the pyedbglib Python module into /usr/lib/python3/dist-packages/.
EOF

echo "Building Debian package..."
dpkg-buildpackage -us -uc

echo "Debian package built successfully."

# Copy the resulting .deb package to ~/packages
cd ..
DEB_FILE="${PACKAGE_NAME}_${VERSION}_all.deb"
echo "Looking for ${DEB_FILE}..."
if [ -f "$DEB_FILE" ]; then
    mkdir -p ~/packages
    cp "$DEB_FILE" ~/packages/
    echo "Copied $DEB_FILE to ~/packages/"
else
    echo "Error: .deb file not found: $DEB_FILE"
    exit 1
fi

# Remove build files
rm -rf pyedbglib python-pyedbglib*



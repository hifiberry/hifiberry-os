#!/bin/bash

set -e

# Define variables
PKG_NAME="baseconfig"
PKG_VERSION="1.0.0"
PKG_MAINTAINER="HiFiBerry <support@hifiberry.com>"
PKG_DESCRIPTION="Base configuration script"
INSTALL_PATH="/usr/sbin"
SCRIPT_NAME="baseconfig"

BUILD_DIR="build"
DEB_DIR="$BUILD_DIR/$PKG_NAME-$PKG_VERSION"
CONTROL_FILE="$DEB_DIR/DEBIAN/control"
POSTINST_FILE="$DEB_DIR/DEBIAN/postinst"
OUTPUT_DIR="$HOME/packages"

# Clean up previous builds
clean() {
    echo "Cleaning up previous builds..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
}

# Create the directory structure for the Debian package
prepare_package_structure() {
    echo "Preparing package structure..."
    mkdir -p "$DEB_DIR/DEBIAN"
    mkdir -p "$DEB_DIR/$INSTALL_PATH"
}

# Create the control file
create_control_file() {
    echo "Creating control file..."
    cat > "$CONTROL_FILE" <<EOL
Package: $PKG_NAME
Version: $PKG_VERSION
Section: utils
Priority: optional
Architecture: all
Maintainer: $PKG_MAINTAINER
Description: $PKG_DESCRIPTION
EOL
}

# Create the post-installation script
create_postinst_file() {
    echo "Creating post-installation script..."
    cat > "$POSTINST_FILE" <<EOL
#!/bin/bash
set -e

echo "Running $SCRIPT_NAME after installation..."
$INSTALL_PATH/$SCRIPT_NAME || true

exit 0
EOL
    chmod 755 "$POSTINST_FILE"
}

# Copy the script to the package directory
copy_files() {
    echo "Copying files..."
    cp "$SCRIPT_NAME" "$DEB_DIR/$INSTALL_PATH/"
    chmod 755 "$DEB_DIR/$INSTALL_PATH/$SCRIPT_NAME"
}

# Build the Debian package
build_package() {
    echo "Building Debian package..."
    dpkg-deb --build "$DEB_DIR"
    mkdir -p "$OUTPUT_DIR"
    mv "$DEB_DIR.deb" "$OUTPUT_DIR/${PKG_NAME}_${PKG_VERSION}_all.deb"
    echo "Package built: $OUTPUT_DIR/${PKG_NAME}_${PKG_VERSION}_all.deb"
}

# Main function
main() {
    clean
    prepare_package_structure
    create_control_file
    create_postinst_file
    copy_files
    build_package
}

main "$@"


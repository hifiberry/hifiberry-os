#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="hifiberry-webui"
REPO_URL="https://github.com/hifiberry/hbos-ui"
SRC_DIR="src"

# Check for the --clean option
if [[ "$1" == "--clean" ]]; then
    ./clean.sh
    exit 0
fi

# Step 1: Clone or update the GitHub repository into src directory
cd "$SRC_DIR"

# Extract version from debian/changelog (now that we're in the right directory)
VERSION=$(head -1 debian/changelog | sed 's/.*(\([^)]*\)).*/\1/')
echo "Building version: $VERSION"

if [[ -d "hbos-ui/.git" ]]; then
    echo "Updating hbos-ui source from $REPO_URL..."
    cd hbos-ui
    git pull
    cd ..
elif [ ! -d "hbos-ui" ]; then
    echo "Cloning hbos-ui source from $REPO_URL..."
    git clone "$REPO_URL" hbos-ui
fi

# Step 2: Build the Vue.js application using Docker
echo "Building Vue.js application with Docker..."
# We're already in the src directory from Step 1
# Ensure dist directory exists and has correct permissions
mkdir -p hbos-ui/dist
docker build -t hifiberry-webui-builder .
# Run Docker as current user to avoid root-owned files
docker run --rm --user "$(id -u):$(id -g)" -v "$(pwd)/hbos-ui/dist:/output" hifiberry-webui-builder sh -c "cp -r /app/dist/* /output/"
# Verify the build was successful
ls -la hbos-ui/dist/
echo "Vue.js build completed successfully"

# Copy dist to debian directory so dpkg-deb can find it
echo "Copying dist directory for packaging..."
mkdir -p debian/hifiberry-webui/usr/share/hifiberry/webui
cp -r hbos-ui/dist/* debian/hifiberry-webui/usr/share/hifiberry/webui/

# Install configure-webui script
mkdir -p debian/hifiberry-webui/usr/bin
cp configure-webui debian/hifiberry-webui/usr/bin/
chmod 755 debian/hifiberry-webui/usr/bin/configure-webui

# Fix file permissions for web assets
find debian/hifiberry-webui/usr/share/hifiberry/webui -type f -name "*.ttf" -exec chmod 644 {} \;
find debian/hifiberry-webui/usr/share/hifiberry/webui -type f -name "*.svg" -exec chmod 644 {} \;
find debian/hifiberry-webui/usr/share/hifiberry/webui -type f -name "*.ico" -exec chmod 644 {} \;
find debian/hifiberry-webui/usr/share/hifiberry/webui -type f -name "*.html" -exec chmod 644 {} \;
find debian/hifiberry-webui/usr/share/hifiberry/webui -type f -name "*.js" -exec chmod 644 {} \;
find debian/hifiberry-webui/usr/share/hifiberry/webui -type f -name "*.css" -exec chmod 644 {} \;

# Create DEBIAN directory and extract binary package control info
mkdir -p debian/hifiberry-webui/DEBIAN

# Extract binary package section from debian/control and add version
# Get Maintainer from source section and binary package section
{
    awk '/^Maintainer:/{print}' debian/control
    awk '/^Package:/{found=1} found{print}' debian/control | sed 's/${misc:Depends}, //g'
} | sed "/^Package:/a Version: $VERSION" > debian/hifiberry-webui/DEBIAN/control

# Copy postinst script
cp debian/postinst debian/hifiberry-webui/DEBIAN/postinst
chmod 755 debian/hifiberry-webui/DEBIAN/postinst

# Copy prerm script  
cp debian/prerm debian/hifiberry-webui/DEBIAN/prerm
chmod 755 debian/hifiberry-webui/DEBIAN/prerm

# Step 3: Build the Debian package using dpkg-deb
echo "Building Debian package with dpkg-deb..."
dpkg-deb --build debian/hifiberry-webui
# Rename to include version in filename
mv debian/hifiberry-webui.deb ../hifiberry-webui_${VERSION}_all.deb

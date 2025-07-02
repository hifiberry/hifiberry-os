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

# Copy dist to debian directory so sbuild can find it
echo "Copying dist directory for sbuild..."
mkdir -p debian/webui-dist
cp -r hbos-ui/dist/* debian/webui-dist/
ls -la debian/webui-dist/
# Stay in src directory for sbuild

# Step 3: Build the Debian package using sbuild
echo "Building Debian package with sbuild..."
if [[ -n "$DIST" ]]; then
    sbuild --chroot-mode=unshare --no-clean-source --dist="$DIST" --arch-all
else
    sbuild --chroot-mode=unshare --no-clean-source --arch-all
fi

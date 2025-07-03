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
# Replace API configuration with production version before building
echo "Using production API configuration..."
cp api.production.ts hbos-ui/src/constants/api.ts
echo "API configuration updated for production build"
# Ensure dist directory exists and has correct permissions
mkdir -p hbos-ui/dist
docker build -t hifiberry-webui-builder .
# Run Docker as current user to avoid root-owned files
docker run --rm --user "$(id -u):$(id -g)" -v "$(pwd)/hbos-ui/dist:/output" hifiberry-webui-builder sh -c "cp -r /app/dist/* /output/"
# Verify the build was successful
ls -la hbos-ui/dist/
echo "Vue.js build completed successfully"

# Copy built files to debian directory so they're included in the source package
echo "Preparing built files for sbuild..."
mkdir -p debian/webui-dist
cp -r hbos-ui/dist/* debian/webui-dist/
echo "Built files copied to debian/webui-dist/"

# Step 3: Build the Debian package using sbuild
echo "Building Debian package with sbuild..."
sbuild -d stable --chroot-mode=unshare --no-run-lintian
# The package will be built in the parent directory automatically by sbuild

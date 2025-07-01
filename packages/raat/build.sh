#!/bin/bash

# Exit on error
set -e

PACKAGE="hifiberry-raat"
VERSION="$(cat $(dirname $(realpath $0))/version.txt | tr -d '\n')"

# Version consistency check
SCRIPT_DIR="$(dirname $(realpath $0))"
CHANGELOG_VERSION=$(grep -m1 "^${PACKAGE}" "${SCRIPT_DIR}/src/debian/changelog" | sed 's/.*(\([^)]*\)).*/\1/')
if [ "$VERSION" != "$CHANGELOG_VERSION" ]; then
    echo "ERROR: Version mismatch!"
    echo "  version.txt: $VERSION"
    echo "  debian/changelog: $CHANGELOG_VERSION"
    echo "Please update version.txt or debian/changelog to match."
    exit 1
fi
echo "Version consistency check passed: $VERSION"

# Check if DIST is set by environment variable
if [ -n "$DIST" ]; then
    echo "Using distribution from DIST environment variable: $DIST"
    CHROOT="${DIST}-amd64-sbuild"
    DIST_ARG="--dist=$DIST"
    CHROOT_ARG="--chroot=$CHROOT"
else
    echo "No DIST environment variable set, using sbuild default"
    DIST_ARG=""
    CHROOT_ARG=""
fi
BUILD_DIR="/tmp/${PACKAGE}-build"
SRC_DIR="$(dirname $(realpath $0))/src"
REPO_URL="https://github.com/hifiberry/raat"
REPO_DIR="$SRC_DIR/raat"

# Parse arguments
NO_UPDATE=false
for arg in "$@"; do
  case $arg in
    --no-update)
      NO_UPDATE=true
      shift
      ;;
  esac
done

echo "Building $PACKAGE version $VERSION"

# Update the repository in src/raat if it exists; otherwise, clone it
if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning repository from $REPO_URL to $REPO_DIR..."
    git clone "$REPO_URL" "$REPO_DIR"
else
    if [ "$NO_UPDATE" = false ]; then
        echo "Repository already exists at $REPO_DIR. Updating..."
        cd "$REPO_DIR"
        git pull
        cd "$SCRIPT_DIR"
    else
        echo "Repository already exists at $REPO_DIR, skipping update due to --no-update flag."
    fi
fi

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy source files to build directory
echo "Copying debian/ files..."
cp -r "$SRC_DIR/debian" "$BUILD_DIR/"
echo "Copying raat.service..."
cp "$SRC_DIR/raat.service" "$BUILD_DIR/"
echo "Copying raat/ directory..."
cp -r "$SRC_DIR/raat" "$BUILD_DIR/"

# Create configure-raat.py with version replacement
echo "Creating configure-raat.py with version $VERSION..."
sed "s/###MYVERSION###/$VERSION/g" "$SRC_DIR/configure-raat.py" > "$BUILD_DIR/configure-raat.py"

# Verify the copy worked
echo "Contents of build directory after copy:"
ls -la "$BUILD_DIR"
echo "Contents of raat directory:"
ls -la "$BUILD_DIR/raat" || echo "ERROR: raat directory not found!"

# Change to build directory
cd "$BUILD_DIR"

# Build package using sbuild
echo "Using sbuild..."
sbuild \
    --chroot-mode=unshare \
    --no-clean-source \
    --enable-network \
    $DIST_ARG \
    $CHROOT_ARG \
    --build-dir="$BUILD_DIR" \
    --verbose

# Move build artifacts to script directory
echo "Moving build artifacts..."
mv *.deb "$SCRIPT_DIR/" 2>/dev/null || true
mv *.changes "$SCRIPT_DIR/" 2>/dev/null || true
mv *.buildinfo "$SCRIPT_DIR/" 2>/dev/null || true

# Clean up build directory
echo "Cleaning up build directory..."
rm -rf "$BUILD_DIR"

echo "Package built successfully"
echo "Built packages:"
ls -la "$SCRIPT_DIR"/*.deb 2>/dev/null || echo "No packages found"


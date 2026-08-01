#!/bin/bash

# Exit on error
set -e

cd "$(dirname "$0")"

# Define variables
PACKAGE="licman"
REPO_URL="https://github.com/hifiberry/licman.git"

# Note: licman is a private repository, so this needs credentials that can
# read it. That was equally true while it was a submodule.

# Check for the --clean option
if [[ "$1" == "--clean" ]]; then
    ./clean.sh
    exit 0
fi

# Step 1: Clone or update the source repository
if [[ -d "$PACKAGE/.git" ]]; then
    echo "Updating $PACKAGE source from $REPO_URL..."
    git -C "$PACKAGE" pull
else
    echo "Cloning $PACKAGE source from $REPO_URL..."
    git clone "$REPO_URL" "$PACKAGE"
fi

# Step 2: Build via the repository's own build script
cd "$PACKAGE"
chmod +x ./build.sh
./build.sh

# Step 3: Move the built packages next to this script
cd ..
find "$PACKAGE" -maxdepth 2 -name "licman_*.deb" -exec mv {} . \; 2>/dev/null || true
find "$PACKAGE" -maxdepth 2 -name "licman_*.changes" -exec mv {} . \; 2>/dev/null || true
find "$PACKAGE" -maxdepth 2 -name "licman_*.buildinfo" -exec mv {} . \; 2>/dev/null || true

echo "Package build completed."
echo "Built packages:"
ls -lh licman*.deb 2>/dev/null || echo "No .deb files found"

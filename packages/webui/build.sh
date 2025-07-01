#!/bin/bash

# Exit on error
set -e

# Define variables
PACKAGE="hifiberry-webui"
REPO_URL="https://github.com/hifiberry/hbos-ui"
SRC_DIR="src"
DIST=${DIST:-bullseye}

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
else
    echo "Cloning hbos-ui source from $REPO_URL..."
    git clone "$REPO_URL" hbos-ui
fi

# Step 2: Build the Debian package using sbuild
echo "Building Debian package with sbuild..."
sbuild --dist="$DIST" --arch-all

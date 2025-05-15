#!/bin/bash

# Exit on error
set -e

# Set MPD version
MPD_VERSION="0.24.3"
MPC_VERSION="0.35"

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DOCKER_DIR="$SCRIPT_DIR/mpd-docker-build"
OUT_DIR="$SCRIPT_DIR/out"

# Ensure output directory exists
mkdir -p "$OUT_DIR"

# Build the Docker image
echo "Building Docker image..."
docker build --progress=plain  -t mpd-build "$DOCKER_DIR"

# Run the Docker container to build the package - interactive mode to show build output
echo "Building MPD package..."
docker run --name mpd_build \
    -e MPD_VERSION="$MPD_VERSION" \
    -e MPC_VERSION="$MPC_VERSION" \
    mpd-build

# Copy the build artifacts from the container
echo "Copying build artifacts..."
docker cp "mpd_build:/out/." "$OUT_DIR"

# Clean up the container
docker rm mpd_build

echo "Package build complete! Check $OUT_DIR for the package."
#!/bin/bash

set -e

# Configuration
VERSION="0.3.4"
PACKAGE_NAME="hifiberry-spotifyd"
DOCKER_TAG="spotifyd-build-env"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKER_DIR="${SCRIPT_DIR}/spotifyd-docker-build"
OUTPUT_DIR="${SCRIPT_DIR}/out"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Build Docker image
echo "Building Docker image for spotifyd build environment..."
docker build -t "$DOCKER_TAG" "$DOCKER_DIR"

# Create package in Docker container - run in interactive mode to see build output
echo "Building package in Docker container for reproducible build..."
docker run --name spotifyd_build \
    -e SPOTIFYD_VERSION="$VERSION" \
    "$DOCKER_TAG"

# Copy the build artifacts from the container
echo "Copying build artifacts..."
docker cp "spotifyd_build:/out/." "$OUTPUT_DIR"

# Clean up the container
docker rm spotifyd_build

echo "Package build complete! Check $OUTPUT_DIR for the package."


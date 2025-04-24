#!/bin/bash

set -e

# Configuration
VERSION="4.3.7"
VERSION_POSTFIX=2 # 1,2,3,... unset when VERSION increases to start from 0 again
PACKAGE_NAME="hifiberry-shairport"
DOCKER_TAG="shairport-build-env"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKER_DIR="${SCRIPT_DIR}/shairport-docker-build"
OUTPUT_DIR="${SCRIPT_DIR}/out"

# Construct full version string - append VERSION_POSTFIX if it exists
FULL_VERSION="${VERSION}"
if [ -n "${VERSION_POSTFIX}" ]; then
    FULL_VERSION="${VERSION}.${VERSION_POSTFIX}"
fi

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Build Docker image
echo "Building Docker image for shairport-sync build environment..."
docker build --progress=plain -t "$DOCKER_TAG" "$DOCKER_DIR"

# Create package in Docker container - run in foreground to see build output
echo "Building package in Docker container for reproducible build..."
docker run --name shairport_build \
    -e "SHAIRPORT_VERSION=$VERSION" \
    -e "PACKAGE_VERSION=$FULL_VERSION" \
    "$DOCKER_TAG"

# Copy package from container after build
echo "Copying package from container..."
PKG_NAME="${PACKAGE_NAME}_${FULL_VERSION}-1_arm64.deb"
docker cp "shairport_build:/out/$PKG_NAME" "$OUTPUT_DIR/"

# Clean up container
docker rm shairport_build

# Show build results
echo "Package build complete. Output available in ${OUTPUT_DIR}"
ls -la "$OUTPUT_DIR"


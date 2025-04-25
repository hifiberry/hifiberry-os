#!/bin/bash

set -e

# Configuration
VERSION="2.0.0"
COMMIT_ID="db51a7b16934f41b72437394bf8114c3a85e0a91"
PACKAGE_NAME="hifiberry-squeezelite"
DOCKER_TAG="squeezelite-build-env"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKER_DIR="${SCRIPT_DIR}/squeezelite-docker-build"
OUTPUT_DIR="${SCRIPT_DIR}/out"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Print help message
function print_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --help          Display this help message"
}

# Process command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --help)
            print_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_help
            exit 1
            ;;
    esac
done

# Build Docker image
echo "Building Docker image for Squeezelite build environment..."
docker build --progress=plain -t "$DOCKER_TAG" "$DOCKER_DIR"

# Build package in Docker container - run in foreground to see build output
echo "Building package in Docker container for reproducible build..."
docker run --name squeezelite_build \
    -e "SQUEEZELITE_VERSION=$VERSION" \
    -e "COMMIT_ID=$COMMIT_ID" \
    "$DOCKER_TAG"

# Copy package from container after build 
echo "Copying package from container..."
PKG_NAME="${PACKAGE_NAME}_${VERSION}_arm64.deb"
docker cp "squeezelite_build:/out/$PKG_NAME" "$OUTPUT_DIR/"

# Clean up container
docker rm squeezelite_build

# Show build results
echo "Package build complete. Output available in ${OUTPUT_DIR}"
ls -la "$OUTPUT_DIR"


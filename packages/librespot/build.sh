#!/bin/bash

set -e

# Configuration
VERSION="0.6.0"
VERSION_POSTFIX=2 # 1,2,3,... unset when VERSION increases to start from 0 again
COMMIT_ID="59381ccad38ed39037392f3d2d30bf0d9593ff56"  # Optional specific commit ID to use (overrides VERSION if set)
PACKAGE_NAME="hifiberry-librespot"
DOCKER_TAG="librespot-build-env"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKER_DIR="${SCRIPT_DIR}/librespot-docker-build"
OUTPUT_DIR="${SCRIPT_DIR}/out"
DEPENDENCIES="python3-configurator (>= 1.4.2)"

# Construct full version string - append VERSION_POSTFIX if it exists
FULL_VERSION="${VERSION}"
if [ -n "${VERSION_POSTFIX}" ]; then
    FULL_VERSION="${VERSION}.${VERSION_POSTFIX}"
fi

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Print help message
function print_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --commit-id ID   Specify a specific commit ID to build (overrides version)"
    echo "  --help           Display this help message"
}

# Process command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --commit-id)
            COMMIT_ID="$2"
            shift 2
            ;;
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
echo "Building Docker image for librespot build environment..."
docker build --progress=plain -t "$DOCKER_TAG" "$DOCKER_DIR"

# Build package in Docker container - run in foreground to see build output
echo "Building package in Docker container for reproducible build..."
docker run --name librespot_build \
    -e "LIBRESPOT_VERSION=$VERSION" \
    -e "PACKAGE_VERSION=$FULL_VERSION" \
    -e "COMMIT_ID=$COMMIT_ID" \
    -e "DEPENDENCIES=$DEPENDENCIES" \
    "$DOCKER_TAG"

# Copy package from container after build
echo "Copying package from container..."
PKG_NAME="${PACKAGE_NAME}_${FULL_VERSION}_arm64.deb"
docker cp "librespot_build:/out/$PKG_NAME" "$OUTPUT_DIR/"

# Clean up container
docker rm librespot_build

# Show build results
echo "Package build complete. Output available in ${OUTPUT_DIR}"
ls -la "$OUTPUT_DIR"


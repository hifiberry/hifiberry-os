#!/bin/bash

# Build script for hifiberry-webui package
# This script is called during the sbuild process

set -e

echo "Starting hifiberry-webui build process..."

# Check if we're in the right directory
if [ ! -d "hbos-ui" ]; then
    echo "Error: hbos-ui directory not found" >&2
    exit 1
fi

echo "Build completed successfully."

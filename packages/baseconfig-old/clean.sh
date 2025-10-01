#!/bin/bash

set -e

# Configuration
BUILD_DIR="/tmp/build-hifiberry-baseconfig"

echo "Cleaning up build artifacts..."
rm -rf "$BUILD_DIR"
rm -f hifiberry-baseconfig_*
echo "Cleanup complete."

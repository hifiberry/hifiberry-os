#!/bin/bash

set -e

# Configuration
BUILD_DIR="/tmp/build-hifiberryos-meta"

echo "Cleaning up build artifacts..."
rm -rf "$BUILD_DIR"
rm -f hifiberryos-meta_*
rm -f hbos-*_*_*.deb
echo "Cleanup complete."

#!/bin/bash

# Exit on error
set -e

SCRIPT_DIR="$(dirname $(realpath $0))"
cd "$SCRIPT_DIR"

echo "Cleaning up build artifacts..."

# Remove build artifacts
rm -f *.deb
rm -f *.changes
rm -f *.buildinfo
rm -f *.dsc
rm -f *.tar.*

# Remove temporary build directories
rm -rf /tmp/hifiberry-squeezelite-build

echo "Cleanup complete"

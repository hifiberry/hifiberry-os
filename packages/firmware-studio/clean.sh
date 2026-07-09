#!/bin/bash

# Exit on error
set -e

SCRIPT_DIR="$(dirname $(realpath $0))"
cd "$SCRIPT_DIR"

echo "Cleaning up build artifacts..."

rm -f *.deb
rm -f *.changes
rm -f *.buildinfo
rm -f *.dsc
rm -f *.tar.*

rm -rf /tmp/firmware-studio-build

echo "Cleanup complete"

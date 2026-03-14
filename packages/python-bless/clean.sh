#!/bin/bash
echo "Cleaning up python3-bless build artifacts..."
SCRIPT_DIR="$(dirname $(realpath $0))"
rm -f "$SCRIPT_DIR"/*.deb "$SCRIPT_DIR"/*.changes "$SCRIPT_DIR"/*.buildinfo
rm -rf /tmp/python3-bless-build
echo "Cleaned up python3-bless build artifacts."

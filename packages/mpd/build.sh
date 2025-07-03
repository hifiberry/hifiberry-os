#!/bin/bash

set -e

# Configuration
PACKAGE_NAME="hifiberry-mpd"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR="${SCRIPT_DIR}/out"

# Extract version from changelog as single source of truth
cd src
FULL_VERSION=$(head -1 debian/changelog | sed 's/.*(\([^)]*\)).*/\1/')
echo "Version from changelog: $FULL_VERSION"
cd ..

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Process command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if DIST is set by environment variable
if [ -n "$DIST" ]; then
    echo "Using distribution from DIST environment variable: $DIST"
    DIST_ARG="--dist=$DIST"
else
    echo "No DIST environment variable set, using sbuild default"
    DIST_ARG=""
fi

# Building package with sbuild
echo "Building package with sbuild..."

# Check if MPD version in rules file is consistent with changelog version
cd src
RULES_MPD_VERSION=$(grep '^MPD_VERSION = ' debian/rules | sed 's/MPD_VERSION = //')
if [[ ! "$FULL_VERSION" =~ ^${RULES_MPD_VERSION}(\.|$) ]]; then
    echo "ERROR: MPD version in rules file ($RULES_MPD_VERSION) is not compatible with package version ($FULL_VERSION)"
    echo "Package version should start with the MPD version from rules file"
    echo "Please update debian/rules or debian/changelog to ensure consistency"
    exit 1
fi

echo "Version consistency check passed: $FULL_VERSION"

# Make sure debian/rules is executable
chmod +x debian/rules

# Use sbuild to build the package
sbuild --chroot-mode=unshare \
       --no-clean-source \
       --enable-network $DIST_ARG

# Go back to parent directory
cd ..

echo "Package build completed."
echo "Built packages:"
ls -la src/../*.deb 2>/dev/null || echo "No .deb files found"
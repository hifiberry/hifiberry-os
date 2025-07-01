#!/bin/bash

set -e

# Configuration
MPD_VERSION="0.24.4.2"
MPC_VERSION="0.35"
PACKAGE_NAME="hifiberry-mpd"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR="${SCRIPT_DIR}/out"

# Construct full version string
FULL_VERSION="${MPD_VERSION}"

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

# Check if the changelog version matches the expected version
cd src
CHANGELOG_VERSION=$(head -1 debian/changelog | sed 's/.*(\([^)]*\)).*/\1/')
if [ "$CHANGELOG_VERSION" != "$FULL_VERSION" ]; then
    echo "ERROR: Changelog version ($CHANGELOG_VERSION) does not match expected version ($FULL_VERSION)"
    echo "Please update debian/changelog manually"
    exit 1
fi

# Check if MPD version in rules file is consistent with build script
RULES_MPD_VERSION=$(grep '^MPD_VERSION = ' debian/rules | sed 's/MPD_VERSION = //')
if [[ ! "$FULL_VERSION" =~ ^${RULES_MPD_VERSION}(\.|$) ]]; then
    echo "ERROR: MPD version in rules file ($RULES_MPD_VERSION) is not compatible with package version ($FULL_VERSION)"
    echo "Package version should start with the MPD version from rules file"
    echo "Please update debian/rules or build.sh to ensure consistency"
    exit 1
fi

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
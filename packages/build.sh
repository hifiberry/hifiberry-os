#!/bin/bash

set -e

# ---------------------------------------------------------
# Determine script directory
# ---------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------
# Load build functions
# ---------------------------------------------------------

source "${SCRIPT_DIR}/build-functions.sh"

# ---------------------------------------------------------
# Determine package directory
# ---------------------------------------------------------

PACKAGE_DIR="${1:-}"

if [[ -z "$PACKAGE_DIR" ]]; then
    echo "Usage: $0 <package-directory> [--clean]"
    exit 1
fi

PACKAGE_DIR="$(realpath "$PACKAGE_DIR")"
SRC_DIR="${PACKAGE_DIR}/src"

if [[ ! -d "$SRC_DIR" ]]; then
    echo "ERROR: Source directory not found:"
    echo "       $SRC_DIR"
    exit 1
fi

# ---------------------------------------------------------
# Package information
# ---------------------------------------------------------

get_package_info "$PACKAGE_DIR"

print_package_info "$PACKAGE" "$VERSION"

# ---------------------------------------------------------
# Handle command line arguments
# ---------------------------------------------------------

if [[ "${2:-}" == "--clean" ]]; then
    clean_build "$PACKAGE" "$BUILD_DIR"
    exit 0
fi

# ---------------------------------------------------------
# Setup
# ---------------------------------------------------------

setup_cross_compile

# ---------------------------------------------------------
# Distribution
# ---------------------------------------------------------

setup_distribution

# ---------------------------------------------------------
# Build
# ---------------------------------------------------------

echo
echo "Building ${PACKAGE} ${VERSION}..."
echo

cd "$SRC_DIR"

build_package

# ---------------------------------------------------------
# Artifacts
# ---------------------------------------------------------

echo
echo "Debian package build completed."

show_build_artifacts "$PACKAGE_DIR"

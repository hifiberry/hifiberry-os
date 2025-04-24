#!/bin/bash
#
# version-helper.sh - Helper functions for package version handling
#
# This script provides consistent version handling for all HiFiBerry OS packages
#

# Function to create a full version string with postfix if provided
# Usage: get_full_version BASE_VERSION [POSTFIX]
get_full_version() {
    local BASE_VERSION="$1"
    local VERSION_POSTFIX="${2:-}"
    
    # Return base version if no postfix is provided
    if [ -z "$VERSION_POSTFIX" ]; then
        echo "$BASE_VERSION"
        return
    fi
    
    # Return version with postfix
    echo "${BASE_VERSION}.${VERSION_POSTFIX}"
}

# Function to parse a version string into its components
# Usage: parse_version VERSION
parse_version() {
    local VERSION="$1"
    local MAJOR=$(echo "$VERSION" | cut -d. -f1)
    local MINOR=$(echo "$VERSION" | cut -d. -f2)
    local PATCH=$(echo "$VERSION" | cut -d. -f3)
    local POSTFIX=$(echo "$VERSION" | cut -d. -f4)
    
    echo "MAJOR: $MAJOR"
    echo "MINOR: $MINOR"
    echo "PATCH: $PATCH"
    echo "POSTFIX: $POSTFIX"
}

# Export environment variable VERSION_POSTFIX if set
# This allows package scripts to use it directly
export VERSION_POSTFIX=${VERSION_POSTFIX:-}
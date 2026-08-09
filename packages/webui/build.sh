#!/bin/bash

# Exit on error
set -e

# Enable cross-compile support if configured
_CC_ENV="$(dirname "$0")/../../scripts/cross-compile-env.sh"
if [ -f "$_CC_ENV" ]; then source "$_CC_ENV"; else echo "Not using cross-compilation (${_CC_ENV} does not exist)"; fi

# Define variables
PACKAGE="hifiberry-webui"
REPO_URL="https://github.com/hifiberry/hbos-ui"
MYDIR=`pwd`

# Check for command line options
NO_LINTIAN=false
for arg in "$@"; do
    case $arg in
        --clean)
            ./clean.sh
            exit 0
            ;;
        --no-lintian)
            NO_LINTIAN=true
            ;;
    esac
done

# Step 1: Clone or update the GitHub repository
cd "$MYDIR"

if [[ -d "hbos-ui/.git" ]]; then
    echo "Updating hbos-ui source from $REPO_URL..."
    cd hbos-ui
    git pull
    cd ..
elif [ ! -d "hbos-ui" ]; then
    echo "Cloning hbos-ui source from $REPO_URL..."
    git clone "$REPO_URL" hbos-ui
fi

# Extract version from debian/changelog (now in hbos-ui/)
VERSION=$(head -1 hbos-ui/debian/changelog | sed 's/.*(\([^)]*\)).*/\1/')
echo "Building version: $VERSION"

# Step 2: Call the build script in hbos-ui to build the package
echo "Calling build script in hbos-ui directory..."
cd hbos-ui
if [[ "$NO_LINTIAN" == true ]]; then
    ./build.sh --no-lintian
else
    ./build.sh
fi

# Step 3: The hbos-ui build script handles moving files
echo "Build completed by hbos-ui script"

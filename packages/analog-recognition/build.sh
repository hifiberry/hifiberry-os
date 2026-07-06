#!/bin/bash
set -e

# Enable cross-compile support if configured
_CC_ENV="$(dirname "$0")/../../scripts/cross-compile-env.sh"
if [ -f "$_CC_ENV" ]; then source "$_CC_ENV"; else echo "Not using cross-compilation (${_CC_ENV} does not exist)"; fi

PACKAGE="analog-recognition"
REPO_URL="https://github.com/hifiberry/analog-recognition"

if [[ "$1" == "--clean" ]]; then
    rm -rf "$PACKAGE"
    rm -f hifiberry-analog-recognition_* hifiberry-analog-recognition-*
    echo "Cleanup completed."
    exit 0
fi

# Clone or update upstream (tracks main HEAD)
if [[ -d "$PACKAGE/.git" ]]; then
    echo "Updating $PACKAGE from $REPO_URL..."
    ( cd "$PACKAGE" && git pull )
else
    echo "Cloning $PACKAGE from $REPO_URL..."
    git clone "$REPO_URL" "$PACKAGE"
fi

cd "$PACKAGE"

if [ -n "$DIST" ]; then
    DIST_ARG="--dist=$DIST"
else
    DIST_ARG=""
fi

echo "Building with sbuild..."
sbuild --chroot-mode=unshare --enable-network --no-clean-source $DIST_ARG

cd ..

# Keep only the .deb; prune other build artifacts
find . -maxdepth 1 \( -name "*.build" -o -name "*.buildinfo" -o -name "*.changes" \
    -o -name "*.dsc" -o -name "*.tar.gz" -o -name "*.tar.xz" \) -delete

LATEST_DEB=$(ls -t hifiberry-analog-recognition_*.deb 2>/dev/null | head -1)
if [ -n "$LATEST_DEB" ]; then
    ls -t hifiberry-analog-recognition_*.deb | tail -n +2 | xargs -r rm -f
fi

echo "Package created:"
ls -lh hifiberry-analog-recognition_*.deb 2>/dev/null || ls -lh *.deb
echo "Build completed successfully!"

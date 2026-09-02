#!/bin/bash
set -e

# Enable cross-compile support if configured
_CC_ENV="$(dirname "$0")/../../scripts/cross-compile-env.sh"
if [ -f "$_CC_ENV" ]; then source "$_CC_ENV"; else echo "Not using cross-compilation (${_CC_ENV} does not exist)"; fi

PACKAGE="songcompare"
REPO_URL="https://github.com/hifiberry/songcompare"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR"

if [[ "$1" == "--clean" ]]; then
    rm -rf "$PACKAGE"
    rm -f hifiberry-songcompare_* hifiberry-songcompare-*
    echo "Cleanup completed."
    exit 0
fi

# Clone or update upstream (tracks master HEAD)
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

# Network stays enabled: cargo fetches the crate dependencies during the build.
echo "Building with sbuild..."
sbuild --chroot-mode=unshare --enable-network --no-clean-source $DIST_ARG

cd ..

# Keep only the .deb; prune other build artifacts
find . -maxdepth 1 \( -name "*.build" -o -name "*.buildinfo" -o -name "*.changes" \
    -o -name "*.dsc" -o -name "*.tar.gz" -o -name "*.tar.xz" \) -delete

LATEST_DEB=$(ls -t hifiberry-songcompare_*.deb 2>/dev/null | head -1)
if [ -n "$LATEST_DEB" ]; then
    ls -t hifiberry-songcompare_*.deb | tail -n +2 | xargs -r rm -f
fi

echo "Package created:"
ls -lh hifiberry-songcompare_*.deb 2>/dev/null || ls -lh *.deb
echo "Build completed successfully!"

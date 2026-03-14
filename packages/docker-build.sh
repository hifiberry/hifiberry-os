#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

IMAGE_NAME="hifiberryos-builder"
CONTAINER_NAME="hifiberryos-build"
CHROOT_VOLUME="hifiberryos-sbuild-cache"

usage() {
    echo "Usage: $0 [OPTIONS] <package|all> [package2 ...]"
    echo
    echo "Build HiFiBerryOS packages in a Docker container."
    echo
    echo "Options:"
    echo "  --clean       Clean and rebuild (remove existing .deb files first)"
    echo "  --rebuild-image  Force rebuild of the Docker image"
    echo "  --shell       Open a shell in the build container"
    echo "  --stop        Stop and remove the build container"
    echo
    echo "Examples:"
    echo "  $0 eeprom                Build a single package"
    echo "  $0 eeprom mpd webui      Build multiple packages"
    echo "  $0 all                   Build all packages"
    echo "  $0 --clean all           Clean and rebuild all packages"
    echo "  $0 --shell               Open a shell in the container"
    exit 1
}

# Parse options
CLEAN_MODE=false
REBUILD_IMAGE=false
SHELL_MODE=false
STOP_MODE=false
PACKAGES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean)
            CLEAN_MODE=true
            shift
            ;;
        --rebuild-image)
            REBUILD_IMAGE=true
            shift
            ;;
        --shell)
            SHELL_MODE=true
            shift
            ;;
        --stop)
            STOP_MODE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            PACKAGES+=("$1")
            shift
            ;;
    esac
done

# --- Stop mode ---
if [ "$STOP_MODE" = true ]; then
    echo "Stopping build container..."
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
    echo "Done."
    exit 0
fi

# --- Ensure Docker image exists ---
ensure_image() {
    if [ "$REBUILD_IMAGE" = true ] || ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
        echo "Building Docker image '$IMAGE_NAME'..."
        docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
    fi
}

# --- Ensure container is running ---
ensure_container() {
    if docker inspect "$CONTAINER_NAME" &>/dev/null; then
        # Container exists — make sure it's running
        if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" != "true" ]; then
            docker start "$CONTAINER_NAME"
        fi
    else
        # Create persistent container with project mounted and sbuild cache volume
        docker run -d \
            --name "$CONTAINER_NAME" \
            --privileged \
            -v "$PROJECT_DIR:/work" \
            -v "$CHROOT_VOLUME:/home/builder/.cache/sbuild" \
            "$IMAGE_NAME" \
            sleep infinity
    fi
}

# --- Run command in container ---
run_in_container() {
    # Use -it only when stdin is a terminal (interactive use)
    local TTY_FLAG=""
    if [ -t 0 ]; then
        TTY_FLAG="-it"
    fi
    docker exec $TTY_FLAG "$CONTAINER_NAME" "$@"
}

# --- Shell mode ---
if [ "$SHELL_MODE" = true ]; then
    ensure_image
    ensure_container
    run_in_container bash
    exit 0
fi

# Need at least one package
if [ ${#PACKAGES[@]} -eq 0 ]; then
    usage
fi

# --- Resolve "all" to list of packages ---
if [ "${PACKAGES[0]}" = "all" ]; then
    PACKAGES=()
    for dir in "$SCRIPT_DIR"/*/; do
        if [ -f "$dir/build.sh" ]; then
            PACKAGES+=("$(basename "$dir")")
        fi
    done
    echo "Building all packages: ${PACKAGES[*]}"
fi

# --- Validate packages exist ---
for pkg in "${PACKAGES[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$pkg/build.sh" ]; then
        echo "ERROR: No build.sh found for package '$pkg'"
        exit 1
    fi
done

ensure_image
ensure_container

# --- Create the sbuild chroot if it doesn't exist yet ---
run_in_container bash -c '
    CHROOT="/home/builder/.cache/sbuild/trixie-arm64-hifiberry.tar.zst"
    if [ ! -f "$CHROOT" ]; then
        echo "Creating sbuild chroot (one-time setup)..."
        /work/scripts/create-chroot --arch arm64 --dist trixie
    else
        echo "sbuild chroot already cached."
    fi
'

# --- Enable cross-compile wrapper in container ---
run_in_container bash -c '
    if [ ! -f /work/scripts/sbuild ]; then
        /work/scripts/enable-cross-compile --arch arm64 --dist trixie
    fi
'

# --- Build each package ---
FAILED=()
SUCCEEDED=()

for pkg in "${PACKAGES[@]}"; do
    echo
    echo "========================================"
    echo "  Building: $pkg"
    echo "========================================"
    echo

    BUILD_ARGS=""
    if [ "$CLEAN_MODE" = true ]; then
        # Run clean.sh if it exists
        run_in_container bash -c "
            cd /work/packages/$pkg
            if [ -f clean.sh ]; then
                chmod +x clean.sh
                ./clean.sh
            fi
            rm -f *.deb 2>/dev/null || true
        " || true
    else
        # Skip if .deb files already exist
        if ls "$SCRIPT_DIR/$pkg/"*.deb 1>/dev/null 2>&1; then
            echo "Package '$pkg' already has .deb files. Skipping (use --clean to force rebuild)."
            SUCCEEDED+=("$pkg (cached)")
            continue
        fi
    fi

    if run_in_container bash -c "
        cd /work/packages/$pkg
        chmod +x build.sh
        export DIST=trixie
        ./build.sh
    "; then
        SUCCEEDED+=("$pkg")
    else
        echo "FAILED: $pkg"
        FAILED+=("$pkg")
    fi
done

# --- Summary ---
echo
echo "========================================"
echo "  Build Summary"
echo "========================================"
if [ ${#SUCCEEDED[@]} -gt 0 ]; then
    echo "  Succeeded: ${SUCCEEDED[*]}"
fi
if [ ${#FAILED[@]} -gt 0 ]; then
    echo "  FAILED:    ${FAILED[*]}"
    exit 1
fi
echo "  All builds completed successfully."

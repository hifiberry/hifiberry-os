#!/bin/bash

setup_cross_compile() {
    local script_dir
    local cc_env

    script_dir="$(dirname "$(realpath "${BASH_SOURCE[1]}")")"
    cc_env="${script_dir}/../scripts/cross-compile-env.sh"

    if [[ -f "$cc_env" ]]; then
        echo "Enabling cross-compilation..."
        source "$cc_env"
    else
        echo "Not using cross-compilation (${cc_env} does not exist)"
    fi
}


get_package_info() {
    local script_dir="$1"
    local changelog="${script_dir}/src/debian/changelog"

    if [[ ! -f "$changelog" ]]; then
        echo "ERROR: Changelog not found: $changelog" >&2
        return 1
    fi

    PACKAGE="$(dpkg-parsechangelog -l "$changelog" -S Source)"
    VERSION="$(dpkg-parsechangelog -l "$changelog" -S Version)"

    if [[ -z "$PACKAGE" ]]; then
        echo "ERROR: Could not determine package name from $changelog" >&2
        return 1
    fi

    if [[ -z "$VERSION" ]]; then
        echo "ERROR: Could not determine package version from $changelog" >&2
        return 1
    fi
}

print_package_info() {
    local package="$1"
    local version="$2"

    echo
    echo "========================================"
    echo " Package"
    echo "========================================"
    echo " Name    : ${package}"
    echo " Version : ${version}"
    echo "========================================"
    echo

    sleep 3
}

setup_distribution() {
    if [[ -n "${DIST:-}" ]]; then
        echo "Using distribution from DIST environment variable: $DIST"

        DIST_ARG="--dist=${DIST}"
        CHROOT_ARG="--chroot=${CHROOT}"
    else
        echo "No DIST environment variable set, using sbuild default"

        DIST_ARG=""
        CHROOT_ARG=""
    fi
}


clean_build() {
    local package="$1"
    local build_dir="$2"

    echo "Cleaning up build files..."

    rm -rf "$build_dir"

    rm -f \
        "${package}"*.build \
        "${package}"*.changes \
        "${package}"*.dsc \
        "${package}"*.deb \
        "${package}"*.buildinfo \
        "${package}"*.tar.*

    echo "Cleanup completed."
}


build_package() {
    echo "Building package with sbuild..."

    sbuild \
        --chroot-mode=unshare \
        --no-clean-source \
        --enable-network \
        ${DIST_ARG:+$DIST_ARG} \
        ${CHROOT_ARG:+$CHROOT_ARG} \
        --verbose
}


show_build_artifacts() {
    local directory="$1"

    echo "$directory"
    echo
    echo "========================================"
    echo " Built packages"
    echo "========================================"

    shopt -s nullglob
    local packages=("${directory}"/*.deb)
    shopt -u nullglob

    if (( ${#packages[@]} > 0 )); then
        for package_file in "${packages[@]}"; do
            echo "   $(basename "$package_file")"
        done
    else
        echo "  No packages found."
    fi

    echo "========================================"
    echo
}

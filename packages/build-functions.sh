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

get_source_directory() {
    if [[ -n "${REPO_URL:-}" ]]; then
        SOURCE="${REPO_URL##*/}"
    else
        SOURCE="src"
    fi
}

get_package_info() {
    local script_dir="$1"
    local changelog="${script_dir}/debian/changelog"

    if [[ ! -f "$changelog" ]]; then
        echo "ERROR: Changelog not found: $changelog" >&2
        return 1
    fi

    PACKAGE="$(dpkg-parsechangelog -l "$changelog" -S Source)"
    DEBIAN_VERSION="$(dpkg-parsechangelog -l "$changelog" -S Version)"

    if [[ -f "${script_dir}/Cargo.toml" ]]; then
        CARGO_VERSION=$(grep -m1 '^version = ' "${script_dir}/Cargo.toml" |
            sed 's/version = "\([^"]*\)"/\1/')
    fi

    if [[ -f "${script_dir}/_version.py" ]]; then
        PYTHON_VERSION=$(grep -m1 '^__version__ = ' "${script_dir}/_version.py" |
            sed 's/__version__ = "\([^"]*\)"/\1/')
    fi

    if [[ -f "${script_dir}/VERSION" ]]; then
        FILE_VERSION=$(tr -d '\n' < "${script_dir}/VERSION")
    fi

    if [[ -z "$PACKAGE" ]]; then
        echo "ERROR: Could not determine package name from $changelog" >&2
        return 1
    fi

    if [[ -z "$DEBIAN_VERSION" ]]; then
        echo "ERROR: Could not determine Debian version from $changelog" >&2
        return 1
    fi
}


print_package_info() {
    echo
    echo "========================================"
    echo " Package"
    echo "========================================"
    echo " Name            : ${PACKAGE}"
    echo " Debian Version  : ${DEBIAN_VERSION}"

    local version_mismatch=0

    if [[ -n "${CARGO_VERSION:-}" ]]; then
        echo " Cargo Version   : ${CARGO_VERSION}"

        if [[ "$DEBIAN_VERSION" != "$CARGO_VERSION" ]]; then
            echo " Version check   : FAILED"
            echo "   Debian : ${DEBIAN_VERSION}"
            echo "   Cargo  : ${CARGO_VERSION}"
            version_mismatch=1
        else
            echo " Version check   : OK"
        fi
    fi

    if [[ -n "${PYTHON_VERSION:-}" ]]; then
        echo " Python Version  : ${PYTHON_VERSION}"

        if [[ "$DEBIAN_VERSION" != "$PYTHON_VERSION" ]]; then
            echo " Version check   : FAILED"
            echo "   Debian : ${DEBIAN_VERSION}"
            echo "   Python : ${PYTHON_VERSION}"
            version_mismatch=1
        else
            echo " Version check   : OK"
        fi
    fi

    if [[ -n "${FILE_VERSION:-}" ]]; then
        echo " VERSION File    : ${FILE_VERSION}"

        if [[ "$DEBIAN_VERSION" != "$FILE_VERSION" ]]; then
            echo " Version check   : FAILED"
            echo "   Debian : ${DEBIAN_VERSION}"
            echo "   VERSION : ${FILE_VERSION}"
            version_mismatch=1
        else
            echo " Version check   : OK"
        fi
    fi

    if (( version_mismatch )); then
        echo
        echo "ERROR: One or more version checks failed!"
        echo
        exit 1
    fi

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

clone_update_git_repo() {
    if [[ -d "${PACKAGE_DIR}/${SOURCE}/.git" && ! -n "${REPO_TAG:-}" ]]; then
        echo "Updating $SOURCE from $REPO_URL..."

        cd "${PACKAGE_DIR}/${SOURCE}"
        git pull
    elif [[ ! -d "${PACKAGE_DIR}/${SOURCE}/.git" ]]; then
        echo "Cloning $SOURCE from $REPO_URL..."
        git clone "$REPO_URL" "${PACKAGE_DIR}/${SOURCE}"
    fi

    if [[ -n "${REPO_TAG:-}" ]]; then
        echo "Checking out tag ${REPO_TAG}..."

        cd "${PACKAGE_DIR}/${SOURCE}"
        git fetch --tags
        git checkout "tags/${REPO_TAG}"
    fi

    cd $PACKAGE_DIR/..
}

clean_build() {
    echo "Cleaning up build and source files..."

    if [[ -n "${REPO_URL:-}" ]]; then
        rm -rf "${PACKAGE_DIR}/${SOURCE}"
        exit 1
    fi

    rm -f \
        "${PACKAGE_DIR}"/*.build \
        "${PACKAGE_DIR}"/*.changes \
        "${PACKAGE_DIR}"/*.dsc \
        "${PACKAGE_DIR}"/*.deb \
        "${PACKAGE_DIR}"/*.buildinfo \
        "${PACKAGE_DIR}"/*.tar.*

    echo "Cleanup completed."
}


build_package() {
    echo "Building package..."

    if [[ -n "${REPO_URL:-}" && -f "./build.sh" ]]; then
        echo "REPO_URL configured and build.sh found, executing..."
        bash "./build.sh"
    elif [[ -n "${REPO_URL:-}" && -f "./build-deb.sh" ]]; then
        echo "REPO_URL configured and build-deb.sh found, executing..."
        bash "./build-deb.sh"
    elif [[ -n "${REPO_URL:-}" && -f "./Makefile" ]] && grep -qE '^[[:space:]]*deb[[:space:]]*:' "./Makefile"; then
        echo "REPO_URL configured and Makefile with deb target found, executing 'make deb'..."
        make deb
    else
        echo "Using sbuild..."

        sbuild \
            --chroot-mode=unshare \
            --no-clean-source \
            --enable-network \
            ${DIST_ARG:+$DIST_ARG} \
            ${CHROOT_ARG:+$CHROOT_ARG} \
            --no-run-lintian \
            --verbose
    fi
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

copy_source_files() {
    if [[ -n "${REPO_URL:-}" && -d "$PACKAGE_DIR/src" ]]; then
        echo "Copying source files into external repo..."
        cp -a "$PACKAGE_DIR/src/." "$PACKAGE_DIR/$SOURCE/"
    fi
}

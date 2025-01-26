#!/bin/bash

set -e

# Configuration
VERSION="1.0.0"
MAINTAINER="HiFiBerry <support@hifiberry.com>"
WORK_DIR="$HOME/src/debian"
OUTPUT_DIR="$HOME/packages"
DEPENDENCY_FILES=("dependencies.light" "dependencies.full" "dependencies.test")

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

function clean() {
    echo "Cleaning up..."
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

function merge_dependencies() {
    local base_file="$1"
    local merged_file="${WORK_DIR}/${base_file}.merged"

    # Ensure dependencies.full includes dependencies.light
    if [[ "$base_file" == "dependencies.full" ]]; then
        echo "Merging dependencies from dependencies.light into $base_file..." >&2
        cat dependencies.light "$base_file" | sort -u > "$merged_file"
        echo "Merged dependencies saved to $merged_file" >&2
    else
        cp "$base_file" "$merged_file"
    fi

    # Only return the merged file path
    echo "$merged_file"
}

function build_package() {
    local package_name=$1
    local dependencies_file=$2

    # Merge dependencies if needed
    local merged_dependencies_file
    merged_dependencies_file=$(merge_dependencies "$dependencies_file")

    # Check if the merged file exists
    if [ ! -f "$merged_dependencies_file" ]; then
        echo "Error: Merged dependencies file $merged_dependencies_file not found!"
        ls $merged_dependencies_file
        exit 1
    fi

    # Read dependencies from the file
    local dependencies
    dependencies=$(tr '\n' ',' < "$merged_dependencies_file" | sed 's/,$//')

    # Prepare package directory
    local package_dir="${WORK_DIR}/${package_name}"
    mkdir -p "${package_dir}/DEBIAN"

    # Create control file
    cat > "${package_dir}/DEBIAN/control" <<EOL
Package: $package_name
Version: $VERSION
Architecture: all
Depends: $dependencies
Source: $package_name
Section: metapackages
Priority: optional
Maintainer: $MAINTAINER
Build-Depends: debhelper-compat (= 13)
Standards-Version: 4.6.0
Homepage: https://hifiberry.com/os
Description: Meta-package for $package_name dependencies
 This meta-package ensures the installation of dependencies for $package_name:
$(echo "$dependencies" | tr ',' '\n' | sed 's/^/  - /')
EOL

    # Debugging: Show generated control file
    echo "Generated control file for $package_name:"
    cat "${package_dir}/DEBIAN/control"
    echo "--- End of control file ---"

    # Set permissions
    chmod -R 755 "${package_dir}"

    # Build the package
    dpkg-deb --build "${package_dir}" "${OUTPUT_DIR}/${package_name}_${VERSION}_all.deb"
    echo "Package created: ${OUTPUT_DIR}/${package_name}_${VERSION}_all.deb"
}

function build_meta_packages() {
    for dependency_file in "${DEPENDENCY_FILES[@]}"; do
        local base_name
        base_name=$(basename "$dependency_file" .dependencies | sed 's/dependencies\.//')
        local package_name="hifiberryos-$base_name"
        build_package "$package_name" "$dependency_file"
    done
}

# Main logic
case "$1" in
    --clean)
        clean
        ;;
    *)
        build_meta_packages
        ;;
esac


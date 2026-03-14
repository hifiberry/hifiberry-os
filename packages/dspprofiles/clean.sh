#!/bin/bash

# Exit on error
set -e

SCRIPT_DIR="$(dirname $(realpath $0))"
DSP_PROFILES_CHECKOUT="$SCRIPT_DIR/dspprofiles"

echo "DSP Profiles clean script"

# Check for --all option to remove the entire checkout
if [[ "$1" == "--all" ]]; then
    echo "Removing entire dspprofiles checkout..."
    if [[ -d "$DSP_PROFILES_CHECKOUT" ]]; then
        rm -rf "$DSP_PROFILES_CHECKOUT"
        echo "DSP profiles checkout removed"
    else
        echo "No dspprofiles checkout found"
    fi
    
    # Also clean any packages in the parent directory
    echo "Cleaning build artifacts in parent directory..."
    cd "$SCRIPT_DIR"
    rm -f *.deb *.changes *.buildinfo *.dsc *.tar.* *.build
    echo "Build artifacts cleaned"
else
    echo "Cleaning build artifacts..."
    
    # Clean the checkout directory if it exists and has a clean script
    if [[ -d "$DSP_PROFILES_CHECKOUT" ]]; then
        if [[ -f "$DSP_PROFILES_CHECKOUT/clean.sh" ]]; then
            echo "Found clean script in dspprofiles checkout, executing it..."
            cd "$DSP_PROFILES_CHECKOUT"
            chmod +x clean.sh
            ./clean.sh "$@"
            cd "$SCRIPT_DIR"
        else
            echo "No clean script found in dspprofiles checkout"
            echo "Cleaning common build artifacts manually..."
            cd "$DSP_PROFILES_CHECKOUT"
            rm -f *.deb *.changes *.buildinfo *.dsc *.tar.* *.build
            cd "$SCRIPT_DIR"
        fi
    else
        echo "No dspprofiles checkout found"
    fi
    
    # Clean any packages in the parent directory
    echo "Cleaning build artifacts in parent directory..."
    cd "$SCRIPT_DIR"
    rm -f *.deb *.changes *.buildinfo *.dsc *.tar.* *.build
    
    echo "Use --all to completely remove the dspprofiles checkout"
fi

echo "DSP profiles clean completed"

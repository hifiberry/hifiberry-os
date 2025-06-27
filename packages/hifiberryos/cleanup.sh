#!/bin/bash

# Clean up incorrectly moved files that don't belong to hifiberryos-meta
echo "Cleaning up incorrectly moved files..."

# Remove files that don't belong to our meta-packages
rm -f hifiberry-raat_*
rm -f hifiberry-shairport_*
rm -f hifiberry-squeezelite_*
rm -f python3-pyalsaaudio_*
rm -f python3-pyedbglib_*
rm -f python3-pymcuprog_*
rm -f python3-usagecollector_*
rm -f python3-xmltodict_*
rm -f testtools_*

echo "Cleanup completed. Remaining files should only be hifiberryos-meta and hbos-* packages."
ls -la *.deb *.dsc *.tar.* *.changes *.buildinfo 2>/dev/null || echo "No package files found"

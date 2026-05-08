#!/bin/bash

echo "Cleaning up build artifacts..."
rm -rf src/target/
rm -rf src/debian/cargo_home/
rm -f hifiberry-vu-meter_*.deb
rm -f hifiberry-vu-meter_*.changes
rm -f hifiberry-vu-meter_*.buildinfo
rm -f hifiberry-vu-meter_*.dsc
rm -f hifiberry-vu-meter_*.build
rm -f hifiberry-vu-meter_*.tar.gz
rm -rf sbuild_workspace/
echo "Cleaned up hifiberry-vu-meter build artifacts."

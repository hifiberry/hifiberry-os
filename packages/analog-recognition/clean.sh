#!/bin/bash
cd "$(dirname "$0")"
echo "Cleaning up analog-recognition build artifacts..."
rm -rf analog-recognition
rm -f hifiberry-analog-recognition_*
rm -f hifiberry-analog-recognition-*
echo "Cleaned up analog-recognition build artifacts."

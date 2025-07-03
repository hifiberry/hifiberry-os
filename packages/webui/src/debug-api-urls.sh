#!/bin/bash

# Debug script to check API URLs in built webui files
# Usage: ./debug-api-urls.sh [path-to-webui-directory]

WEBUI_DIR="${1:-/usr/share/hifiberry/webui}"

if [ ! -d "$WEBUI_DIR" ]; then
    echo "WebUI directory not found: $WEBUI_DIR"
    echo "Usage: $0 [path-to-webui-directory]"
    exit 1
fi

echo "=== Checking API URLs in $WEBUI_DIR ==="
echo

echo "1. Files containing 'api' (case insensitive):"
find "$WEBUI_DIR" -name "*.js" -type f -exec grep -l -i "api" {} \; | head -10

echo
echo "2. API URL patterns found:"
find "$WEBUI_DIR" -name "*.js" -type f -exec grep -H -n "http.*api\|localhost.*api\|:[0-9]*.*api\|API_BASE_URL\|/api" {} \; | head -20

echo
echo "3. Checking for hardcoded URLs:"
find "$WEBUI_DIR" -name "*.js" -type f -exec grep -H -n "localhost:[0-9]" {} \; | head -10

echo
echo "4. Current window.location usage:"
find "$WEBUI_DIR" -name "*.js" -type f -exec grep -H -n "window\.location" {} \; | head -10

echo
echo "=== Done ==="

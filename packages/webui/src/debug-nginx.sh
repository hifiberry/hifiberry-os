#!/bin/bash

# Debug script to check nginx configuration for HiFiBerry Web UI and API

echo "=== HiFiBerry Web UI nginx Debug ==="
echo

echo "1. Checking nginx service status:"
systemctl is-active nginx || echo "nginx is not running"
echo

echo "2. Checking if nginx include files exist:"
ls -la /etc/nginx/hifiberry-*.nginx 2>/dev/null || echo "No HiFiBerry nginx files found"
echo

echo "3. Checking nginx sites:"
echo "Sites available:"
ls -la /etc/nginx/sites-available/hifiberry* 2>/dev/null || echo "No HiFiBerry sites available"
echo
echo "Sites enabled:"
ls -la /etc/nginx/sites-enabled/hifiberry* 2>/dev/null || echo "No HiFiBerry sites enabled"
echo

echo "4. Checking nginx configuration syntax:"
nginx -t
echo

echo "5. Checking for conflicting default sites:"
ls -la /etc/nginx/sites-enabled/default* 2>/dev/null || echo "No default sites enabled"
echo

echo "6. Current nginx server configuration:"
echo "Main nginx.conf includes:"
grep -n "include.*sites-enabled" /etc/nginx/nginx.conf || echo "No sites-enabled include found"
echo

echo "7. HiFiBerry site configuration (if exists):"
if [ -f /etc/nginx/sites-available/hifiberry-webui ]; then
    echo "--- /etc/nginx/sites-available/hifiberry-webui ---"
    cat /etc/nginx/sites-available/hifiberry-webui
else
    echo "No HiFiBerry site configuration found"
fi
echo

echo "8. Testing API connectivity:"
echo "Direct API test (port 1080):"
curl -s -w "HTTP %{http_code}\n" http://localhost:1080/api/version || echo "Failed to connect to API on port 1080"
echo
echo "Nginx proxy test (port 80):"
curl -s -w "HTTP %{http_code}\n" http://localhost:80/api/version || echo "Failed to connect via nginx proxy"
echo

echo "=== Debug complete ==="

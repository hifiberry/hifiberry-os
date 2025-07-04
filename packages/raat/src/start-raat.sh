#!/bin/bash
#
# start-raat.sh - RAAT startup script with Avahi availability check
# This script handles startup of RAAT with Avahi daemon availability verification
#
# Version: 1.0.0
# Changelog:
# - v1.0.0: Initial version with Avahi daemon availability check
#           Waits up to 30 seconds for Avahi to become responsive
#           Ensures reliable mDNS functionality before starting RAAT
#

# MDNS backend - RAAT uses Avahi for mDNS discovery
MDNS_BACKEND="avahi"

# Check if Avahi daemon is running when MDNS_BACKEND is set to avahi
# This ensures RAAT has functioning mDNS capabilities before starting
# We check both that the process exists and that it's actually responding to queries
if [ "$MDNS_BACKEND" = "avahi" ]; then
  echo "Checking if Avahi daemon is running..."
  ATTEMPTS=0
  MAX_ATTEMPTS=6  # 6 attempts x 5 seconds = 30 seconds max wait time
  
  while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    # Check if avahi-daemon is running and listening
    if pgrep avahi-daemon >/dev/null && avahi-browse -a -t >/dev/null 2>&1; then
      echo "Avahi daemon is running and responding."
      break
    else
      ATTEMPTS=$((ATTEMPTS + 1))
      if [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; then
        echo "Avahi daemon is not ready. Waiting 5 seconds... (Attempt $ATTEMPTS/$MAX_ATTEMPTS)"
        sleep 5
      else
        echo "Warning: Avahi daemon is not running or not responding after 30 seconds."
        echo "RAAT may have limited mDNS functionality."
      fi
    fi
  done
fi

# Configure RAAT before starting
echo "Configuring RAAT..."
/usr/bin/configure-raat

# Run the original RAAT application with all provided arguments
echo "Starting RAAT with configuration: $@"
exec /usr/bin/raat_app "$@"

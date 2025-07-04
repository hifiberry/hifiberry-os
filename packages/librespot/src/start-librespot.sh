#!/bin/bash
#
# start-librespot.sh - Librespot startup script
# This script handles startup of librespot with the system's pretty hostname
# and auto-configures audio parameters based on the detected sound card
#
# Version: 1.1.0
# Changelog:
# - v1.1.0: Added Avahi daemon availability check when using Avahi as MDNS backend
#           Waits up to 30 seconds for Avahi to become responsive
#           Added explicit --mdns-backend parameter to librespot options
#

# Set default values for librespot
BITRATE=320
BACKEND="rodio"

# MDNS backend
MDNS_BACKEND="avahi"

# Check if Avahi daemon is running when MDNS_BACKEND is set to avahi
# This ensures Librespot has functioning mDNS capabilities before starting
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
        echo "Librespot may have limited mDNS functionality."
      fi
    fi
  done
fi

# Get the pretty hostname first, then try normal hostname, and finally use HiFiBerry as fallback
PRETTY_HOSTNAME=$(hostnamectl hostname --pretty 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$PRETTY_HOSTNAME" ]; then
  # Try to get normal hostname
  PRETTY_HOSTNAME=$(hostname 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$PRETTY_HOSTNAME" ]; then
    PRETTY_HOSTNAME="HiFiBerry"
  fi
fi

# Path to the event handler script
EVENT_HANDLER="/usr/bin/spotify-event"

# Build basic librespot command with options
LIBRESPOT_CMD="/usr/bin/librespot"
LIBRESPOT_OPTS=("--name" "$PRETTY_HOSTNAME" 
                "--backend" "$BACKEND" 
                "--bitrate" "$BITRATE"
                "--disable-audio-cache"
                "--onevent" "$EVENT_HANDLER"
                "--mdns-backend" "$MDNS_BACKEND")  # Explicitly set the MDNS backend

# Try to get both mixer name and hardware index from configurator
if command -v config-soundcard >/dev/null 2>&1; then
  MIXER_NAME=$(config-soundcard --no-eeprom --volume-control-softvol 2>/dev/null)
  HW_INDEX=$(config-soundcard --no-eeprom --hw 2>/dev/null)
  
  # Only use all three audio options together if both mixer and hw index are available
  if [ $? -eq 0 ] && [ -n "$MIXER_NAME" ] && [ -n "$HW_INDEX" ]; then
    echo "Using mixer control: $MIXER_NAME and hardware device: hw:$HW_INDEX"
    LIBRESPOT_OPTS+=("--mixer" "alsa")
    LIBRESPOT_OPTS+=("--alsa-mixer-control" "$MIXER_NAME")
    LIBRESPOT_OPTS+=("--alsa-mixer-device" "hw:$HW_INDEX")
  fi
fi

# Debug: print the command to be executed
echo "Starting Librespot with device name: $PRETTY_HOSTNAME"
echo "Command: $LIBRESPOT_CMD ${LIBRESPOT_OPTS[@]}"

# Run librespot with the configured options
exec $LIBRESPOT_CMD "${LIBRESPOT_OPTS[@]}"
#!/bin/bash
#
# start-librespot.sh - Librespot startup script
# This script handles startup of librespot with the system's pretty hostname
# and auto-configures audio parameters based on the detected sound card
#
# Version: 1.1.1
# Changelog:
# - v1.1.1: Fixed parameter name from --mdns-backend to --zeroconf-backend for compatibility
#           Updated variable names to match librespot's actual command line options
# - v1.1.0: Added Avahi daemon availability check when using Avahi as MDNS backend
#           Waits up to 30 seconds for Avahi to become responsive
#           Added explicit --mdns-backend parameter to librespot options
#

# User validation check
# Allow running as root, or as the user specified in /etc/hifiberry.user
CURRENT_USER=$(whoami)
if [ "$CURRENT_USER" != "root" ]; then
    if [ -f "/etc/hifiberry.user" ]; then
        AUTHORIZED_USER=$(cat /etc/hifiberry.user 2>/dev/null | tr -d '\n\r ')
        if [ "$CURRENT_USER" != "$AUTHORIZED_USER" ]; then
            echo "Error: not starting librespot, this should run as user $AUTHORIZED_USER"
            exit 0
        fi
    else
        echo "Error: not starting librespot, /etc/hifiberry.user not found and not running as root"
        exit 0
    fi
fi

# Sound card detection check
echo "Checking for sound card..."
if ! /usr/bin/config-soundcard --detect >/dev/null 2>&1; then
    echo "No sound card detected, not starting librespot"
    exit 0
fi
echo "Sound card detected successfully."

# Set default values for librespot
BITRATE=320
BACKEND="rodio"

# MDNS backend
ZEROCONF_BACKEND="avahi"

# Check if Avahi daemon is running when ZEROCONF_BACKEND is set to avahi
# This ensures Librespot has functioning mDNS capabilities before starting
# We check both that the process exists and that it's actually responding to queries
if [ "$ZEROCONF_BACKEND" = "avahi" ]; then
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
        echo "Librespot may have limited zeroconf/mDNS functionality."
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

# check if /usr/bin/audiocontrol_notify_librespot exists and is executable and use this as the event handler
if [ -x /usr/bin/audiocontrol_notify_librespot ]; then
  EVENT_HANDLER="/usr/bin/audiocontrol_notify_librespot"
fi


# Build basic librespot command with options
LIBRESPOT_CMD="/usr/bin/librespot"
LIBRESPOT_OPTS=("--name" "$PRETTY_HOSTNAME" 
                "--backend" "$BACKEND" 
                "--bitrate" "$BITRATE"
                "--disable-audio-cache"
                "--onevent" "$EVENT_HANDLER"
                "--zeroconf-backend" "$ZEROCONF_BACKEND")  # Explicitly set the zeroconf backend

# Check if we can get an access token from audiocontrol
TOKEN=`curl -f http://localhost:1080/api/spotify/access_token`
if [ $? == 0 ]; then
  echo "Successfully obtained access token from audiocontrol, using it"
  LIBRESPOT_OPTS+=("--access-token" "$TOKEN")
else
  echo "No access token available on audiocontrol"
fi

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
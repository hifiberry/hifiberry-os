#!/bin/bash
#
# start-librespot.sh - Librespot startup script
# This script handles startup of librespot with the system's pretty hostname
# and auto-configures audio parameters based on the detected sound card
#

# Set default values for librespot
BITRATE=320
BACKEND="alsa"

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
EVENT_HANDLER="/usr/bin/spotify-event.sh"

# Build basic librespot command with options
LIBRESPOT_CMD="/usr/bin/librespot"
LIBRESPOT_OPTS=("--name" "$PRETTY_HOSTNAME" 
                "--backend" "$BACKEND" 
                "--bitrate" "$BITRATE"
                "--disable-audio-cache"
                "--onevent" "$EVENT_HANDLER")

# Try to get both mixer name and hardware index from configurator
if command -v config-soundcard >/dev/null 2>&1; then
  MIXER_NAME=$(config-soundcard --volume-control-softvol 2>/dev/null)
  HW_INDEX=$(config-soundcard --hw 2>/dev/null)
  
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
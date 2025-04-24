#!/bin/bash
#
# start-shairport.sh - Shairport Sync startup script
# This script handles startup of Shairport Sync with the system's pretty hostname
# as the AirPlay device name
#

# Default values
CONFIG_FILE="/etc/shairport-sync.conf"
METADATA_PIPE="/tmp/shairport-sync-metadata"
PLAYPAUSE_START="/usr/bin/shairport-start"
PLAYPAUSE_STOP="/usr/bin/shairport-stop"

# Get the pretty hostname first, then try normal hostname, and finally use HiFiBerry as fallback
PRETTY_HOSTNAME=$(hostnamectl hostname --pretty 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$PRETTY_HOSTNAME" ]; then
  # Try to get normal hostname
  PRETTY_HOSTNAME=$(hostname 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$PRETTY_HOSTNAME" ]; then
    PRETTY_HOSTNAME="HiFiBerry"
  fi
fi

# Create metadata pipe if it doesn't exist
if [ ! -p "$METADATA_PIPE" ]; then
  mkfifo "$METADATA_PIPE"
fi

# Set permissions for the metadata pipe to allow audio group to read
chmod 660 "$METADATA_PIPE"
chown shairport-sync:audio "$METADATA_PIPE"

# Build shairport-sync command with options
SHAIRPORT_CMD="/usr/bin/shairport-sync"
SHAIRPORT_OPTS=(
  "--name=${PRETTY_HOSTNAME}"
  "--metadata-pipename=${METADATA_PIPE}" 
  "-g"
  "--on-start=${PLAYPAUSE_START}"
  "--on-stop=${PLAYPAUSE_STOP}"
)

# Debug: print the command to be executed
echo "Starting Shairport Sync with device name: $PRETTY_HOSTNAME"
echo "Command: $SHAIRPORT_CMD ${SHAIRPORT_OPTS[@]}"

# Run shairport-sync with the configured options
exec $SHAIRPORT_CMD "${SHAIRPORT_OPTS[@]}"
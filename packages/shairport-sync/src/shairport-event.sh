#!/bin/bash
#
# shairport-event.sh - Script to handle playback state changes
# This script detects whether it's called as *-start or *-stop
# and takes action accordingly
#

# Path to write status to
STATUS_FILE="/tmp/shairport-status"
METADATA_PIPE="/tmp/shairport-sync-metadata"
LOG_FILE="/tmp/shairport-events.log"

# Log the event with timestamp
log_event() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Shairport $1 event" >> "$LOG_FILE"
}

# Handle playback start
on_start() {
  log_event "start"
  echo "playing" > "$STATUS_FILE"
  
  # Optional: Send a system notification
  if command -v notify-send &> /dev/null; then
    notify-send "AirPlay" "Playback started" --icon=audio-headphones
  fi
}

# Handle playback stop
on_stop() {
  log_event "stop"
  echo "stopped" > "$STATUS_FILE"
  
  # Optional: Send a system notification
  if command -v notify-send &> /dev/null; then
    notify-send "AirPlay" "Playback stopped" --icon=audio-headphones
  fi
}

# Determine action based on script name
SCRIPT_NAME=$(basename "$0")

if [[ "$SCRIPT_NAME" == *"-start" ]]; then
  on_start
elif [[ "$SCRIPT_NAME" == *"-stop" ]]; then
  on_stop
else
  echo "Unknown script name. Should be named with -start or -stop suffix."
  exit 1
fi

exit 0
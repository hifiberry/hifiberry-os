#!/bin/bash
#
# shairport-playpause.sh - Script to handle playback state changes
# This script is called with "start" or "stop" arguments when 
# shairport-sync starts or stops playback
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

# Main logic based on the first argument
case "$1" in
  "start")
    on_start
    ;;
  "stop")
    on_stop
    ;;
  *)
    echo "Usage: $0 [start|stop]"
    exit 1
    ;;
esac

exit 0
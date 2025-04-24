#!/bin/bash
#
# shairport-metadata-example.sh - Simple example for using the metadata reader
# This script shows how to use the shairport-sync-metadata-reader
# to extract and display information from the metadata pipe
#

# Path to the metadata pipe
METADATA_PIPE="/tmp/shairport-sync-metadata"
OUTPUT_FILE="/tmp/shairport-metadata.txt"

# Check if metadata pipe exists
if [ ! -p "$METADATA_PIPE" ]; then
  echo "Error: Metadata pipe not found at $METADATA_PIPE"
  echo "Make sure shairport-sync is running with the --metadata-pipename option"
  exit 1
fi

echo "Starting metadata reader example..."
echo "Reading metadata from $METADATA_PIPE"
echo "Press Ctrl+C to stop"

# Run the metadata reader and process the output
/usr/bin/shairport-sync-metadata-reader < "$METADATA_PIPE" | while read -r line; do
  echo "$line" | tee -a "$OUTPUT_FILE"
  
  # Example parsing - extract artist and title
  if echo "$line" | grep -q "artist"; then
    ARTIST=$(echo "$line" | sed -n 's/.*<item><type>artist<\/type><code>asar<\/code><length>[0-9]*<\/length><data>\(.*\)<\/data>.*/\1/p')
    if [ -n "$ARTIST" ]; then
      echo "Artist detected: $ARTIST" | tee -a "$OUTPUT_FILE"
    fi
  fi
  
  if echo "$line" | grep -q "title"; then
    TITLE=$(echo "$line" | sed -n 's/.*<item><type>title<\/type><code>minm<\/code><length>[0-9]*<\/length><data>\(.*\)<\/data>.*/\1/p')
    if [ -n "$TITLE" ]; then
      echo "Title detected: $TITLE" | tee -a "$OUTPUT_FILE"
    fi
  fi
  
  # Example: Detect artwork
  if echo "$line" | grep -q "<code>PICT</code>"; then
    echo "Artwork detected" | tee -a "$OUTPUT_FILE"
  fi
done

echo "Metadata reader stopped"
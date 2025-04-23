#!/bin/bash

# Set the PipeWire version and version suffix directly here
PIPEWIRE_VERSION="1.4.2"
VERSION_SUFFIX="1"  # This will create version 1.4.2.1

cd pipewire-docker-build
if [ ! -d out ]; then
  mkdir out
fi

# Build the Docker image with plain progress output
docker build --progress=plain -t pipewire-builder .

# Run Docker container in foreground mode and build the package
echo "Starting PipeWire build in Docker container version $PIPEWIRE_VERSION.$VERSION_SUFFIX..."
docker run \
  --name pipewire-build-container \
  --env PIPEWIRE_VERSION="$PIPEWIRE_VERSION" \
  --env VERSION_SUFFIX="$VERSION_SUFFIX" \
  pipewire-builder

# Copy the .deb files from the container to the local out directory
echo "Copying .deb files from container..."
docker cp pipewire-build-container:/out/. ./out/

# Remove the container
docker rm pipewire-build-container

# Display success message
echo "Build complete. Output files are in $(pwd)/out/"
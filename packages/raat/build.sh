#!/bin/bash

set -e

cd `dirname $0`

# Read version from version.txt
VERSION=$(cat version.txt)
VERSION_SUFFIX=""  # Leave empty or set to a value like "1" for 1.0.0.1

if [ ! -d out ]; then
  mkdir out
fi

cd raat-docker-build

# Copy version.txt to the docker build directory
cp ../version.txt .

# Clone the RAAT repository outside of the container
echo "Cloning the RAAT repository..."
if [ -d "raat" ]; then
  echo "RAAT repository already exists, updating..."
  cd raat
  git pull
  cd ..
else
  git clone https://github.com/hifiberry/raat
fi

# Build the Docker image with plain progress output
echo "Building Docker image with the RAAT repository included..."
docker build --progress=plain -t raat-builder .

# Run Docker container in foreground mode and build the package
echo "Starting RAAT build in Docker container version $VERSION$VERSION_SUFFIX..."
docker run \
  --name raat-build-container \
  --env VERSION="$VERSION" \
  --env VERSION_SUFFIX="$VERSION_SUFFIX" \
  raat-builder

# Copy the .deb files from the container to the local out directory
echo "Copying .deb files from container..."
docker cp raat-build-container:/out/. ../out/

# Remove the container
docker rm raat-build-container

# Display success message
echo "Build complete. Output files are raat-docker-build/out"


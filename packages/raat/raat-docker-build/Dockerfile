FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV BUILD_DIR=/build
ENV OUT_DIR=/out

# Install necessary packages
RUN apt-get update && apt-get install -y \
    build-essential \
    libglib2.0-dev \
    libdbus-1-dev \
    libdbus-glib-1-dev \
    libasound2-dev \
    fakeroot \
    ca-certificates \
    curl \
    pkg-config

# Create directories
RUN mkdir -p $BUILD_DIR && \
    mkdir -p $OUT_DIR && \
    mkdir -p /tmp

WORKDIR $BUILD_DIR

# Copy the build script and necessary files
COPY compile.sh $BUILD_DIR/
COPY raat.service $BUILD_DIR/
COPY configure-raat $BUILD_DIR/
COPY version.txt $BUILD_DIR/
COPY raat/ $BUILD_DIR/raat/

RUN chmod +x $BUILD_DIR/compile.sh

# Use compile.sh directly as entrypoint
ENTRYPOINT ["/build/compile.sh"]
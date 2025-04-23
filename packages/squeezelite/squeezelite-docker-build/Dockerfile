FROM debian:buster

ENV DEBIAN_FRONTEND=noninteractive
ENV BUILD_DIR=/build
ENV OUT_DIR=/out

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    libflac-dev \
    libmad0-dev \
    libvorbis-dev \
    libmpg123-dev \
    libfaad-dev \
    libasound2-dev \
    fakeroot \
    dh-make \
    devscripts \
    jq \
    ca-certificates \
    wget

# Create directories
RUN mkdir -p $BUILD_DIR && \
    mkdir -p $OUT_DIR

WORKDIR $BUILD_DIR

# Copy the compile script and service files
COPY compile.sh $BUILD_DIR/
COPY squeezelite.service $BUILD_DIR/
COPY start-squeezelite $BUILD_DIR/
RUN chmod +x $BUILD_DIR/compile.sh

# Use compile.sh directly as entrypoint
ENTRYPOINT ["/build/compile.sh"]
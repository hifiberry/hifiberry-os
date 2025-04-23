FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive
ENV BUILD_DIR=/build
ENV OUT_DIR=/out

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    pkg-config \
    libssl-dev \
    libasound2-dev \
    libpulse-dev \
    libdbus-1-dev \
    libglib2.0-dev \
    fakeroot \
    dh-make \
    devscripts \
    debhelper \
    lintian \
    jq \
    ca-certificates \
    wget

# Install Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Create directories
RUN mkdir -p $BUILD_DIR && \
    mkdir -p $OUT_DIR

WORKDIR $BUILD_DIR

# Copy the compile script and service files
COPY compile.sh $BUILD_DIR/
COPY librespot.service $BUILD_DIR/

# Make compile script executable
RUN chmod +x $BUILD_DIR/compile.sh

# Use compile.sh as entrypoint
ENTRYPOINT ["/build/compile.sh"]
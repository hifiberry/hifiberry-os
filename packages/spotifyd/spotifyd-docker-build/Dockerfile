FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV BUILD_DIR=/build
ENV OUT_DIR=/out

# Add Rust repository and install dependencies
RUN apt-get update && apt-get install -y \
    build-essential devscripts fakeroot dh-make \
    wget ca-certificates curl gnupg git \
    libasound2-dev libssl-dev pkg-config

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Create directories
RUN mkdir -p $BUILD_DIR && \
    mkdir -p $OUT_DIR

WORKDIR $BUILD_DIR

# Copy the compile script and systemd service file
COPY compile.sh $BUILD_DIR/
COPY systemd/ $BUILD_DIR/systemd/
RUN chmod +x $BUILD_DIR/compile.sh

# Use compile.sh directly as entrypoint
ENTRYPOINT ["/build/compile.sh"]
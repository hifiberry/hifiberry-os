FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
# Remove hardcoded version, will be passed from build.sh
ENV BUILD_DIR=/build
ENV OUT_DIR=/out

# Add necessary repositories and install dependencies
RUN apt-get update && apt-get install -y \
    build-essential devscripts fakeroot dh-make \
    libssl-dev libavahi-client-dev libpopt-dev libconfig-dev \
    libdaemon-dev libsoxr-dev avahi-daemon xxd libplist-dev \
    libsodium-dev libgcrypt-dev libavutil-dev libavcodec-dev \
    libavformat-dev uuid-dev libasound2-dev pkg-config \
    wget ca-certificates git autoconf automake libtool libsystemd-dev

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
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
    wget ca-certificates git autoconf automake libtool libsystemd-dev \
    libglib2.0-dev libmosquitto-dev

# Create directories
RUN mkdir -p $BUILD_DIR && \
    mkdir -p $OUT_DIR

WORKDIR $BUILD_DIR

# Copy the compile script, start script, event script, metadata example script, and systemd service files
COPY compile.sh $BUILD_DIR/
COPY start-shairport.sh $BUILD_DIR/
COPY shairport-event.sh $BUILD_DIR/
COPY shairport-metadata-example.sh $BUILD_DIR/
COPY systemd/ $BUILD_DIR/systemd/
COPY shairport-sync.conf.default $BUILD_DIR/

# Make scripts executable
RUN chmod +x $BUILD_DIR/compile.sh
RUN chmod +x $BUILD_DIR/start-shairport.sh
RUN chmod +x $BUILD_DIR/shairport-event.sh
RUN chmod +x $BUILD_DIR/shairport-metadata-example.sh

# Use compile.sh directly as entrypoint
ENTRYPOINT ["/build/compile.sh"]
FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV BUILD_DIR=/build
ENV OUT_DIR=/out

# Add necessary repositories and install dependencies
RUN apt-get update && apt-get install -y \
    build-essential debhelper devscripts fakeroot dh-make \
    wget ca-certificates meson \
    libavcodec-dev libavformat-dev libavutil-dev libboost-dev \
    libasound2-dev libflac-dev libid3tag0-dev libmad0-dev libmikmod-dev \
    libpcre2-dev libsndfile1-dev libsoxr-dev libvorbis-dev libopus-dev \
    libsystemd-dev python3-sphinx libsqlite3-dev libcurl4-openssl-dev \
    libyajl-dev libgcrypt20-dev libexpat1-dev zlib1g-dev libfmt-dev \
    libavahi-client-dev ninja-build pkg-config

# Create directories
RUN mkdir -p $BUILD_DIR && \
    mkdir -p $OUT_DIR

WORKDIR $BUILD_DIR

# Copy the compile script, systemd service file, and config files
COPY compile.sh $BUILD_DIR/
COPY systemd/ $BUILD_DIR/systemd/
COPY config/ $BUILD_DIR/config/
RUN chmod +x $BUILD_DIR/compile.sh

# Use compile.sh directly as entrypoint
ENTRYPOINT ["/build/compile.sh"]
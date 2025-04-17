FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV PIPEWIRE_VERSION=1.4.2
ENV BUILD_DIR=/build
ENV OUT_DIR=/out

# Add non-free repositories and then install packages
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates && \
    echo 'deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware' > /etc/apt/sources.list && \
    echo 'deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware' >> /etc/apt/sources.list && \
    echo 'deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware' >> /etc/apt/sources.list && \
    apt-get update && apt-get install -y \
    git curl build-essential meson ninja-build pkg-config \
    systemd libsystemd-dev libdbus-1-dev libudev-dev libspa-0.2-dev \
    libasound2-dev libjack-jackd2-dev libpulse-dev \
    libavahi-client-dev libbluetooth-dev libsbc-dev \
    libldacbt-abr-dev libldacbt-enc-dev libfdk-aac-dev \
    checkinstall ca-certificates

# Create directories
RUN mkdir -p $BUILD_DIR && \
    mkdir -p $OUT_DIR && \
    mkdir -p /tmp

WORKDIR $BUILD_DIR

# Copy the build script
COPY compile.sh $BUILD_DIR/
RUN chmod +x $BUILD_DIR/compile.sh

# Use compile.sh directly as entrypoint
ENTRYPOINT ["/build/compile.sh"]


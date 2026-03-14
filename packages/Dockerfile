FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

# Core build tools
RUN apt-get update && apt-get install -y \
    git bc bison flex libssl-dev make build-essential \
    devscripts dh-make dh-python dpkg-dev \
    python3-setuptools python3-pip python3-all python3-all-dev \
    meson sbuild mmdebstrap uidmap \
    ca-certificates curl figlet tofrodos \
    ruby-full \
    vim less \
    zstd \
    && rm -rf /var/lib/apt/lists/*

# fpm (used by some packages)
RUN gem install fpm

# pip tools (used by some packages)
RUN pip install --break-system-packages build wheel2deb

# Create build user (sbuild --chroot-mode=unshare needs non-root)
RUN useradd -m -s /bin/bash builder \
    && echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER builder
WORKDIR /work

# Pre-create the sbuild chroot cache directory
RUN mkdir -p /home/builder/.cache/sbuild

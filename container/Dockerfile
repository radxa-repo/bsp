# syntax=docker/dockerfile:1

# Podman appears does not support ${TARGETARCH} in FROM
# as such you need to comment out every FROM except the first one
# so you won't rebuild previous layers

FROM debian:bullseye as base-arm64
RUN apt-get update && \
    apt-get full-upgrade --no-install-recommends -y \
        less jq \
        binfmt-support qemu-user-static \
        build-essential gcc-arm-none-eabi git ruby sudo apt-utils \
        python3 python2 python-is-python2 curl debhelper \
        python3-distutils python3-pkg-resources python3-setuptools python3-pyelftools python3-ply python3-git \
        cpio bc flex fakeroot bison rsync kmod swig device-tree-compiler u-boot-tools \
        python2-dev python3-dev libssl-dev uuid-dev libgnutls28-dev
        # python3-cryptography causes build failure for U-Boot latest,
        # but is required for U-Boot mediatek

#FROM base-arm64 as base-amd64
RUN dpkg --add-architecture arm64 && \
    apt-get update && \
    apt-get full-upgrade --no-install-recommends -y \
        crossbuild-essential-arm64 libc6:arm64 libssl-dev:arm64
        # python3-cryptography:arm64

#FROM base-${TARGETARCH} as output
RUN gem install fpm && \
    curl https://bootstrap.pypa.io/pip/2.7/get-pip.py | python2 && \
    python2 -m pip install pyelftools==0.29 && \
    adduser --gecos runner --disabled-password runner && \
    rm -rf /var/lib/apt/lists/*

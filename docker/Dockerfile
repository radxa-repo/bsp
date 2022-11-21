FROM debian:bullseye

RUN dpkg --add-architecture arm64 && \
    apt-get update && \
    apt-get full-upgrade --no-install-recommends -y \
        build-essential crossbuild-essential-arm64 gcc-arm-none-eabi git ruby sudo apt-utils \
        python3 python-is-python3 python3-distutils python3-pkg-resources \
        bc flex bison rsync kmod swig device-tree-compiler \
        python3-dev libssl-dev libssl-dev:arm64 \
        qemu-user-static binfmt-support libc6:arm64 && \
    gem install fpm && \
    adduser --gecos runner --disabled-password runner && \
    rm -rf /var/lib/apt/lists/*

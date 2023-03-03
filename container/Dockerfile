FROM debian:bullseye

RUN sed -i 's/deb.debian.org/apt.vamrs.com/g' /etc/apt/sources.list

RUN dpkg --add-architecture arm64 && \
    apt-get update && \
    apt-get full-upgrade --no-install-recommends -y \
        build-essential crossbuild-essential-arm64 gcc-arm-none-eabi git ruby sudo apt-utils \
        python3 python2 python-is-python2 python3-distutils python3-pkg-resources \
        cpio bc flex fakeroot bison rsync kmod swig device-tree-compiler u-boot-tools \
        python2-dev python3-dev libssl-dev libssl-dev:arm64 \
        libc6:arm64 && \
    gem install fpm && \
    adduser --gecos runner --disabled-password runner && \
    rm -rf /var/lib/apt/lists/*

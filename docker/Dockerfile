FROM debian:bullseye

RUN sed -i 's/deb.debian.org/apt.vamrs.com/g' /etc/apt/sources.list

RUN dpkg --add-architecture arm64 && \
    apt-get update && \
    apt-get full-upgrade -y && \
    apt-get install --no-install-recommends -y \
        build-essential crossbuild-essential-arm64 gcc-arm-none-eabi git ruby \
        python3 python-is-python3 bc flex bison rsync kmod libssl-dev:arm64 \
        qemu-user-static binfmt-support libc6:arm64 && \
    gem install fpm && \
    adduser --gecos runner --disabled-password runner && \
    rm -rf /var/lib/apt/lists/*

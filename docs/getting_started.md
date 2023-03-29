# Getting Started

## Install dependencies

### Debian 12 / Ubuntu 22.04

```bash
sudo apt update
sudo apt install -y git qemu-user-static binfmt-support

# Podman (recommended)
sudo apt install -y podman podman-docker
sudo touch /etc/containers/nodocker
# Docker
#sudo apt install docker.io

# Optional dependcies for minor features
sudo apt install -y systemd-container
```

## Check out the code

`bsp` uses git submodules. As such, please check out the code with the following command:

```bash
git clone --recurse-submodules https://github.com/radxa-repo/bsp.git
```

## Build your first package

Once the repo is cloned on your machine, you can run `bsp` without any arguments to check the help message:

```bash
cd bsp
./bsp
```

Most options listed in the help messages are targetting at developers. If you only want to build a package locally, you can run `bsp` with only the required arguments:

```bash
# Build Linux rockchip
./bsp linux rockchip
# Build U-Boot latest
./bsp u-boot latest
```

Supported Linux and U-Boot profiles are listed at the end of the help message.

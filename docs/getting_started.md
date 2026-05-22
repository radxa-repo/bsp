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

## Understand `bsp`'s usage

Once the repo is cloned on your machine, you can run `bsp` to check the built-in help:

```admonish tip
The built-in help is intended as the first step to troubleshoot for `bsp` usage,
while the documentation site covers more about high level applications and low level
implementation details. As such, you are more likely to find your questions solved
by an option listed in the built-in help.

It is **strongly recommended** to read the built-in help at once, if you want to
do anything beyond the trival package rebuild.
```

```bash
cd bsp
./bsp
```

## Build your first packages

`bsp` now supports building kernel and U-Boot in a single step, and specify them
by product name instead of specific profiles. This should help new users to test
their setup without much `bsp` knowledge:




```bash
# Command Format:

bsp [options] <linux|u-boot> <profile> [product]

```

There are two steps to build packages

1. Get the product name 

    You can get the product name by the method below:

    Download and run the lastest official debian image on board,
    run the `uname -r` on the terminal and get the kernel like `5.10.160-28-rk356x`,
    then the last word such as 'rk356x' is what we want,
     Or you can get the info from reading the source code.

2. build kernel, u-boot

```bash

# you can build the kernel and u-boot together or separately

# Build both kernel and u-boot (e.g. radxa-zero)

./bsp radxa-zero

# Build kernel only (e.g. radxa-zero)

./bsp linux radxa-zero

# Build u-boot only (e.g. radxa-zero)

./bsp u-boot radxa-zero

```

After compilation is completed, many `deb` packages will be generated in the bsp/output directory. You only need to install the following two `deb` packages.

such as

```
linux-headers-5.10.160-20-rk356x_5.10.160-20_arm64.deb
linux-image-5.10.160-20-rk356x_5.10.160-20_arm64.deb
```

The path to the kernel source code is located in the bsp directory at `.src/linux`, and the kernel can be built again after modifying the kernel source code.

If you don't want to sync the lastest code from server, you can add this parameter `--no-prepare-source`, or your modifications will be overwritten.

```
./bsp --no-prepare-source radxa-zero
```
For more bsp parameter usage instructions, you can execute `./bsp` to view.


Custom kernel/firmware developer should at least read the [Development reference](dev_flow.md)
section to better understand the development workflow and the internal data
sctructure for `bsp`.

# Firmware management

## Firmware, or do you mean U-Boot?

`bsp` is intended to be a general *Board Support Package* builder. In this sense,
there are *firmwares* which perform low level initialization, and *kernel* which
runs the operating system. Currently the only kernel `bsp` supports is Linux, and
the only supported firmware is U-Boot. However, we plan to support EDK2 in the
future, thus this section is titled *firmware management*.

## U-Boot installation location

Following Debian convention, we install U-Boot under `/usr/lib/u-boot` folder,
and save all supported bootloaders in a single package.

We also provide a maintenance script called [`setup.sh`](setup_sh.md).

## Extracting binaries from released package

Firmware binaries are usually needed to perform various offline recovery tasks.
As we only release firmware in the form of Debian package, it is necessary to
extract the required files first before performing any recovery steps.

On Windows, you can extract `.deb` files with [7-Zip](https://www.7-zip.org/download.html).

On Linux, you can run following command to extrace the package:

```bash
ar p u-boot-latest.deb data.tar.xz | tar -xJ
```

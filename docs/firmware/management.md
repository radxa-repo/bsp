# Firmware management

## Firmware, or do you mean U-Boot?

`bsp` is intended to be a general *Board Support Package* builder. In this sense, there are *firmwares* which perform low level initialization, and *kernel* which runs the operating system. Currently the only kernel `bsp` supports is Linux, and the only supported firmware is U-Boot. However, we plan to support EDK2 in the future, thus this section is titled *firmware management*.

## U-Boot installation location

Following Debian convention, we install U-Boot under `/usr/lib/u-boot` folder, and save all supported bootloaders in a single package. Under each board's directory, there are a few binary blobs, along with a management script called `setup.sh`, which provides a wrapper for common management tasks.

There is minimal error checking in the script, as such, it is intended as the advanced method of bootloader management. Normal user should use `rsetup` instead, which provides a TUI for bootloader update.

Additionally, not all commands are intended for the end user usage. Below are documented and supported commands:

## Common `setup.sh` command

### `setup.sh maskrom`

Maskrom is a special boot mode, that can run binary passed via USB OTG connection. This is usually the first command to run when you boot the board in maskrom mode.

For Amlogic devices, the binary is actually a normal U-Boot binary running in memory, so you can access the U-Boot console for recovery.

For Rockchip devices, the binary allows access to on-board eMMC via `rkdeveloptool`.

### `setup.sh update_bootloader <file>`

This command update the installed bootloader on a uncompressed system image file. Since block devices is also a file, the command can also update the bootloader on storage medias like eMMC or NVMe SSD.

## Rockchip specific `setup.sh` command

### `setup.sh maskrom_autoupdate_bootloader`

This command update the eMMC bootloader via Rockchip Maskrom mode. You do not need to run `setup.sh maskrom` first when using this command.

### `setup.sh maskrom_autoupdate_spinor`

This command update the SPI bootloader via Rockchip Maskrom mode. You do not need to run `setup.sh maskrom` first when using this command.

### `setup.sh update_spinor [mtd_device]`

This command update the installed bootloader on the SPI flash. When no `mtd_device` is assigned, it will update `/dev/mtd0`.

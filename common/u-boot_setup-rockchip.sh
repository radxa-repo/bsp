#!/bin/bash

build_spinor() {
    if [[ -f "$SCRIPT_DIR/u-boot.itb" ]]
    then
        truncate -s 16M /tmp/spi.img
        dd conv=notrunc,fsync if="$SCRIPT_DIR/idbloader.img" of=/tmp/spi.img bs=512 seek=64
        dd conv=notrunc,fsync if="$SCRIPT_DIR/u-boot.itb" of=/tmp/spi.img bs=512 seek=16384
    elif [[ -f "$SCRIPT_DIR/uboot.img" ]] && [[ -f "$SCRIPT_DIR/trust.img" ]]
    then
        truncate -s 4M /tmp/spi.img
        dd conv=notrunc,fsync if="$SCRIPT_DIR/idbloader-spi.img" of=/tmp/spi.img bs=512 seek=64
        dd conv=notrunc,fsync if="$SCRIPT_DIR/uboot.img" of=/tmp/spi.img bs=512 seek=4096
        dd conv=notrunc,fsync if="$SCRIPT_DIR/trust.img" of=/tmp/spi.img bs=512 seek=6144
    else
        echo "Missing U-Boot binary!" >&2
        return 2
    fi
}

maskrom() {
    rkdeveloptool db "$SCRIPT_DIR/rkboot.bin"
}

maskrom_spinor() {
    rkdeveloptool db "$SCRIPT_DIR/rkboot_SPINOR.bin"
}

maskrom_spinand() {
    rkdeveloptool db "$SCRIPT_DIR/rkboot_SPI_NAND.bin"
}

maskrom_update_bootloader() {
    rkdeveloptool wl 64 "$SCRIPT_DIR/idbloader.img"
    if [[ -f "$SCRIPT_DIR/u-boot.itb" ]]
    then
        rkdeveloptool wl 16384 "$SCRIPT_DIR/u-boot.itb"
    elif [[ -f "$SCRIPT_DIR/uboot.img" ]] && [[ -f "$SCRIPT_DIR/trust.img" ]]
    then
        rkdeveloptool wl 16384 "$SCRIPT_DIR/uboot.img"
        rkdeveloptool wl 24576 "$SCRIPT_DIR/trust.img"
    else
        echo "Missing U-Boot binary!" >&2
        return 2
    fi
}

maskrom_update_spinor() {
    build_spinor
    rkdeveloptool ef
    rkdeveloptool wl 0 /tmp/spi.img
    rm /tmp/spi.img
}

maskrom_dump() {
    local OUTPUT=${1:-dump.img}

    echo "eMMC dump will continue indefinitely."
    echo "Please manually interrupt the process (Ctrl+C)"
    echo "  once the image size is larger than your eMMC size."
    echo "Writting to $OUTPUT..."
    rkdeveloptool rl 0 -1 "$OUTPUT"
}

update_bootloader() {
    local DEVICE=$1

    dd conv=notrunc,fsync if="$SCRIPT_DIR/idbloader.img" of=$DEVICE bs=512 seek=64
    if [[ -f "$SCRIPT_DIR/u-boot.itb" ]]
    then
        dd conv=notrunc,fsync if="$SCRIPT_DIR/u-boot.itb" of=$DEVICE bs=512 seek=16384
    elif [[ -f "$SCRIPT_DIR/uboot.img" ]] && [[ -f "$SCRIPT_DIR/trust.img" ]]
    then
        dd conv=notrunc,fsync if="$SCRIPT_DIR/uboot.img" of=$DEVICE bs=512 seek=16384
        dd conv=notrunc,fsync if="$SCRIPT_DIR/trust.img" of=$DEVICE bs=512 seek=24576
    else
        echo "Missing U-Boot binary!" >&2
        return 2
    fi
    sync
}

update_spinor() {
    if [[ ! -e /dev/mtdblock0 ]]
    then
        echo "/dev/mtdblock0 is missing." >&2
        return 1
    fi

    build_spinor
    flash_erase /dev/mtd0 0 0
    nandwrite -p /dev/mtd0 /tmp/spi.img
    rm /tmp/spi.img
    sync
}

set -euo pipefail
shopt -s nullglob

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

ACTION="$1"
shift

if [[ $(type -t $ACTION) == function ]]
then
    $ACTION "$@"
else
    echo "Unsupported action: '$ACTION'" >&2
    exit 1
fi
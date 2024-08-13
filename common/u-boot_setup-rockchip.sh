#!/bin/bash

if [[ ! -v ERROR_REQUIRE_FILE ]]; then
    readonly ERROR_REQUIRE_FILE=-3
fi
if [[ ! -v ERROR_ILLEGAL_PARAMETERS ]]; then
    readonly ERROR_ILLEGAL_PARAMETERS=-4
fi
if [[ ! -v ERROR_REQUIRE_TARGET ]]; then
    readonly ERROR_REQUIRE_TARGET=-5
fi

idbloader() {
    if [ -e "$SCRIPT_DIR/idbloader-sd_nand.img" ]
    then
        echo "$SCRIPT_DIR/idbloader-sd_nand.img"
    else
        echo "$SCRIPT_DIR/idbloader.img"
    fi
}

rkboot() {
    if [ -e "$SCRIPT_DIR/rkboot_UART0_SD_NAND.bin" ]
    then
        echo "$SCRIPT_DIR/rkboot_UART0_SD_NAND"
    else
        echo "$SCRIPT_DIR/rkboot.bin"
    fi
}

build_spinor() {
    rm -f /tmp/spi.img
    if [[ -f "$SCRIPT_DIR/idbloader-spi_spl.img" ]] && [[ -f "$SCRIPT_DIR/u-boot.itb" ]]
    then
        echo "Building Upstream RK3399 SPI U-Boot..."
        truncate -s 4M /tmp/spi.img
        dd conv=notrunc,fsync if="$SCRIPT_DIR/idbloader-spi_spl.img" of=/tmp/spi.img bs=512
        dd conv=notrunc,fsync if="$SCRIPT_DIR/u-boot.itb" of=/tmp/spi.img bs=512 seek=768
    elif [[ -f "$SCRIPT_DIR/u-boot.itb" ]]
    then
        echo "Building Rockchip RK35 SPI U-Boot..."
        truncate -s 16M /tmp/spi.img
        dd conv=notrunc,fsync if="$(idbloader)" of=/tmp/spi.img bs=512 seek=64
        dd conv=notrunc,fsync if="$SCRIPT_DIR/u-boot.itb" of=/tmp/spi.img bs=512 seek=16384
    elif [[ -f "$SCRIPT_DIR/idbloader-spi.img" ]] && [[ -f "$SCRIPT_DIR/uboot.img" ]] && [[ -f "$SCRIPT_DIR/trust.img" ]]
    then
        echo "Building Rockchip RK33 SPI U-Boot..."
        truncate -s 4M /tmp/spi.img
        dd conv=notrunc,fsync if="$SCRIPT_DIR/idbloader-spi.img" of=/tmp/spi.img bs=512
        dd conv=notrunc,fsync if="$SCRIPT_DIR/uboot.img" of=/tmp/spi.img bs=512 seek=4096
        dd conv=notrunc,fsync if="$SCRIPT_DIR/trust.img" of=/tmp/spi.img bs=512 seek=6144
    else
        echo "Missing U-Boot binary!" >&2
        return "$ERROR_REQUIRE_FILE"
    fi
}

maskrom() {
    rkdeveloptool db "$(rkboot)"
}

maskrom_spinor() {
    if [[ -f "$SCRIPT_DIR/rkboot_SPINOR.bin" ]]
    then
        rkdeveloptool db "$SCRIPT_DIR/rkboot_SPINOR.bin"
    else
        maskrom
    fi
}

maskrom_spinand() {
    if [[ -f "$SCRIPT_DIR/rkboot_SPI_NAND.bin" ]]
    then
        rkdeveloptool db "$SCRIPT_DIR/rkboot_SPI_NAND.bin"
    else
        maskrom
    fi
}

maskrom_update_idbloader() {
    rkdeveloptool wl 64 "$(idbloader)"
}

maskrom_update_bootloader() {
    maskrom_update_idbloader
    if [[ -f "$SCRIPT_DIR/u-boot.itb" ]]
    then
        rkdeveloptool wl 16384 "$SCRIPT_DIR/u-boot.itb"
    elif [[ -f "$SCRIPT_DIR/uboot.img" ]] && [[ -f "$SCRIPT_DIR/trust.img" ]]
    then
        rkdeveloptool wl 16384 "$SCRIPT_DIR/uboot.img"
        rkdeveloptool wl 24576 "$SCRIPT_DIR/trust.img"
    else
        echo "Missing U-Boot binary!" >&2
        return "$ERROR_REQUIRE_FILE"
    fi
}

maskrom_erase_bootloader() {
    dd if=/dev/zero of=/tmp/zero.img bs=1 count=8M
    rkdeveloptool wl 64 /tmp/zero.img
    rm /tmp/zero.img
}

maskrom_erase_spinor() {
    rkdeveloptool ef
}

maskrom_update_spinor() {
    build_spinor
    maskrom_erase_spinor
    rkdeveloptool wl 0 /tmp/spi.img
    rm /tmp/spi.img
}

maskrom_autoupdate_bootloader() {
    maskrom || true
    maskrom_update_bootloader
    maskrom_reset
}

maskrom_autoupdate_spinor() {
    maskrom_spinor || true
    maskrom_update_spinor
    maskrom_reset
}

maskrom_autoerase_bootloader() {
    maskrom || true
    maskrom_erase_bootloader
    maskrom_reset
}

maskrom_autoerase_spinor() {
    maskrom_spinor || true
    maskrom_erase_spinor
    maskrom_reset
}

maskrom_dump() {
    local OUTPUT=${1:-dump.img}

    echo "eMMC dump will continue indefinitely."
    echo "Please manually interrupt the process (Ctrl+C)"
    echo "  once the image size is larger than your eMMC size."
    echo "Writting to $OUTPUT..."
    rkdeveloptool rl 0 -1 "$OUTPUT"
}

maskrom_reset() {
    rkdeveloptool rd
}

update_idbloader() {
    local DEVICE=$1

    dd conv=notrunc,fsync if="$(idbloader)" of=$DEVICE bs=512 seek=64
}

update_bootloader() {
    local DEVICE=$1

    update_idbloader "$DEVICE"
    if [[ -f "$SCRIPT_DIR/u-boot.itb" ]]
    then
        dd conv=notrunc,fsync if="$SCRIPT_DIR/u-boot.itb" of=$DEVICE bs=512 seek=16384
    elif [[ -f "$SCRIPT_DIR/uboot.img" ]] && [[ -f "$SCRIPT_DIR/trust.img" ]]
    then
        dd conv=notrunc,fsync if="$SCRIPT_DIR/uboot.img" of=$DEVICE bs=512 seek=16384
        dd conv=notrunc,fsync if="$SCRIPT_DIR/trust.img" of=$DEVICE bs=512 seek=24576
    else
        echo "Missing U-Boot binary!" >&2
        return "$ERROR_REQUIRE_FILE"
    fi
    sync "$DEVICE"
}

erase_bootloader() {
    local DEVICE=$1

    dd conv=notrunc,fsync if=/dev/zero of=$DEVICE bs=512 seek=64 count=16384
    sync "$DEVICE"
}

erase_spinor() {
    local DEVICE=${1:-/dev/mtd0}

    if [[ ! -e $DEVICE ]]
    then
        echo "$DEVICE is missing." >&2
        return "$ERROR_REQUIRE_TARGET"
    fi

    flash_erase "$DEVICE" 0 0
}

update_spinor() {
    local DEVICE=${1:-/dev/mtd0}

    if [[ ! -e $DEVICE ]]
    then
        echo "$DEVICE is missing." >&2
        return "$ERROR_REQUIRE_TARGET"
    fi

    build_spinor
    erase_spinor "$DEVICE"
    #nandwrite -p "$DEVICE" /tmp/spi.img
    echo "Writting to $DEVICE..."
    flashcp /tmp/spi.img "$DEVICE"
    rm /tmp/spi.img
    sync
}

# https://stackoverflow.com/a/28776166
is_sourced() {
    if [ -n "$ZSH_VERSION" ]
    then 
        case $ZSH_EVAL_CONTEXT in
            *:file:*)
                return 0
                ;;
        esac
    else  # Add additional POSIX-compatible shell names here, if needed.
        case ${0##*/} in
            dash|-dash|bash|-bash|ksh|-ksh|sh|-sh)
                return 0
                ;;
        esac
    fi
    return 1  # NOT sourced.
}

if ! is_sourced
then

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
        exit "$ERROR_ILLEGAL_PARAMETERS"
    fi

fi

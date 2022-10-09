#!/bin/bash

maskrom() {
    local SOC=${1:-$(dtsoc)}

    case "$SOC" in
        amlogic*)
            boot-g12.py "$SCRIPT_DIR/u-boot.bin"
            ;;
        rockchip*)
            rkdeveloptool db "$SCRIPT_DIR/rkboot.bin"
            ;;
        *)
            echo "Unknown SOC." >&2
            return 1
            ;;
    esac
}

update_bootloader() {
    local DEVICE=$1
    local SOC=${2:-$(dtsoc)}

    case "$SOC" in
        amlogic*)
            dd conv=notrunc,fsync if="$SCRIPT_DIR/u-boot.bin.sd.bin" of=$DEVICE bs=1 count=444
            dd conv=notrunc,fsync if="$SCRIPT_DIR/u-boot.bin.sd.bin" of=$DEVICE bs=512 skip=1 seek=1
            ;;
        rockchip*)
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
            ;;
        *)
            echo "Unknown SOC." >&2
            return 1
            ;;
    esac
}

update_spi() {
    if [[ ! -e /dev/mtdblock0 ]]
    then
        echo "/dev/mtdblock0 is missing." >&2
        return 1
    fi

    local SOC=${1:-$(dtsoc)}

    case "$SOC" in
        rockchip*)
            dd conv=notrunc,fsync if="$SCRIPT_DIR/idbloader-spi.img" of=/tmp/spi.img bs=512 seek=64
            if [[ -f "$SCRIPT_DIR/u-boot.itb" ]]
            then
                dd conv=notrunc,fsync if="$SCRIPT_DIR/u-boot.itb" of=/tmp/spi.img bs=512 seek=4096
            elif [[ -f "$SCRIPT_DIR/uboot.img" ]] && [[ -f "$SCRIPT_DIR/trust.img" ]]
            then
                dd conv=notrunc,fsync if="$SCRIPT_DIR/uboot.img" of=/tmp/spi.img bs=512 seek=4096
                dd conv=notrunc,fsync if="$SCRIPT_DIR/trust.img" of=/tmp/spi.img bs=512 seek=6144
            else
                echo "Missing U-Boot binary!" >&2
                return 2
            fi
            flash_eraseall /dev/mtdblock0
            dd conv=notrunc,fsync if=/tmp/spi.img of=/dev/mtdblock0 bs=4096
            rm /tmp/spi.img
            ;;
        *)
            echo "Unknown SOC." >&2
            return 1
            ;;
    esac

}

set -e

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

ACTION="$1"
shift

if [[ $(type -t $ACTION) == function ]]
then
    $ACTION "$@"
else
    echo "Unsupported action: '$ACTION'" >&2
    return 1
fi
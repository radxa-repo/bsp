#!/bin/bash

update_bootloader() {
    local DEVICE=$1
    local SOC=${2:-$(dtsoc)}

    case "$SOC" in
        amlogic*)
            dd conv=notrunc if="$SCRIPT_DIR/u-boot.bin.sd.bin" of=$DEVICE bs=1 count=444
            dd conv=notrunc if="$SCRIPT_DIR/u-boot.bin.sd.bin" of=$DEVICE bs=512 skip=1 seek=1
            ;;
        rockchip*)
            dd conv=notrunc if="$SCRIPT_DIR/idbloader.img" of=$DEVICE bs=512 seek=64
            dd conv=notrunc if="$SCRIPT_DIR/u-boot.itb" of=$DEVICE bs=512 seek=16384
            ;;
        *)
            echo Unknown SOC. >&2
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
            cp "$SCRIPT_DIR/idbloader-spi.img" /tmp/spi.img
            dd conv=notrunc if="$SCRIPT_DIR/u-boot.itb" of=/tmp/spi.img bs=512 seek=768
            dd conv=notrunc if=/tmp/spi.img of=/dev/mtdblock0 bs=4096
            rm /tmp/spi.img
            ;;
        *)
            echo Unknown SOC. >&2
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
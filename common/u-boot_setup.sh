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

maskrom_spinor() {
    local SOC=${1:-$(dtsoc)}

    case "$SOC" in
        amlogic*)
            echo "Amlogic device supports running U-Boot binary from maskrom mode." >&2
            echo "Please retry with maskrom command." >&2
            return 3
            ;;
        rockchip*)
            rkdeveloptool db "$SCRIPT_DIR/rkboot_spinor.bin"
            ;;
        *)
            echo "Unknown SOC." >&2
            return 1
            ;;
    esac
}

maskrom_update_bootloader() {
    local SOC=${1:-$(dtsoc)}

    case "$SOC" in
        amlogic*)
            echo "Amlogic device supports running U-Boot binary from maskrom mode." >&2
            echo "Please retry with update_bootloader command." >&2
            return 3
            ;;
        rockchip*)
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
            ;;
        *)
            echo "Unknown SOC." >&2
            return 1
            ;;
    esac
}

maskrom_update_spinor() {
    local SOC=${1:-$(dtsoc)}

    case "$SOC" in
        rockchip*)
            rkdeveloptool ef
            rkdeveloptool wl 64 "$SCRIPT_DIR/idbloader-spi.img"
            if [[ -f "$SCRIPT_DIR/u-boot.itb" ]]
            then
                rkdeveloptool wl 4096 "$SCRIPT_DIR/u-boot.itb"
            elif [[ -f "$SCRIPT_DIR/uboot.img" ]] && [[ -f "$SCRIPT_DIR/trust.img" ]]
            then
                rkdeveloptool wl 4096 "$SCRIPT_DIR/uboot.img"
                rkdeveloptool wl 6144 "$SCRIPT_DIR/trust.img"
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

maskrom_dump() {
    local SOC=${1:-$(dtsoc)}
    local OUTPUT=${2:-dump.img}

    case "$SOC" in
        amlogic*)
            echo "Amlogic device supports running U-Boot binary from maskrom mode." >&2
            echo "Please retry with update_bootloader command." >&2
            return 3
            ;;
        rockchip*)
            echo "eMMC dump will continue indefinitely."
            echo "Please manually interrupt the process (Ctrl+C)"
            echo "  once the image size is larger than your eMMC size."
            echo "Writting to $OUTPUT..."
            rkdeveloptool rl 0 -1 "$OUTPUT"
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

update_spinor() {
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
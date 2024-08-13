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

maskrom() {
    pushd "$SCRIPT_DIR"
    aiot-bootrom
    popd
}

update_bootloader() {
    local DEVICE=$1

    dd conv=notrunc,fsync if="$SCRIPT_DIR/u-boot.bin.sd.bin" of=$DEVICE bs=1 count=444
    dd conv=notrunc,fsync if="$SCRIPT_DIR/u-boot.bin.sd.bin" of=$DEVICE bs=512 skip=1 seek=1
    sync "$DEVICE"
}

erase_bootloader() {
    local DEVICE=$1

    dd conv=notrunc,fsync if=/dev/zero of=$DEVICE bs=1 count=444
    dd conv=notrunc,fsync if=/dev/zero of=$DEVICE bs=512 skip=1 seek=1 count=2048
    sync "$DEVICE"
}


erase_emmc_boot() {
    if [[ -f "/sys/class/block/$(basename "$1")/force_ro" ]]
    then
        echo 0 > "/sys/class/block/$(basename "$1")/force_ro"
    fi
    blkdiscard -f "$@"
}

update_emmc_boot() {
    if [[ -f "/sys/class/block/$(basename "$1")/force_ro" ]]
    then
        echo 0 > "/sys/class/block/$(basename "$1")/force_ro"
    fi
    update_bootloader "$@"
}

maskrom_update_bootloader() {
    fastboot flash mmc0boot1 "$SCRIPT_DIR/u-boot.bin"
    fastboot erase mmc0boot2
}

maskrom_erase_bootloader() {
    fastboot erase mmc0boot1
    fastboot erase mmc0boot2
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

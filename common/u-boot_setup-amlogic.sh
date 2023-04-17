#!/bin/bash

maskrom() {
    boot-g12.py "$SCRIPT_DIR/u-boot.bin"
}

update_bootloader() {
    local DEVICE=$1

    dd conv=notrunc,fsync if="$SCRIPT_DIR/u-boot.bin.sd.bin" of=$DEVICE bs=1 count=444
    dd conv=notrunc,fsync if="$SCRIPT_DIR/u-boot.bin.sd.bin" of=$DEVICE bs=512 skip=1 seek=1
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
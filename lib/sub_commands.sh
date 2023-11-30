_export() {
    pushd "$SCRIPT_DIR"
    echo "PROFILE_BSP_COMMIT='$(git rev-parse HEAD)'" > ".profile"
    find "linux/$1" "u-boot/$1" ".profile" | tar acvf "$OLDPWD/$1.tar.xz" --files-from -
    popd
}

_import() {
    tar axvf "$1" -C "$SCRIPT_DIR"
    pushd "$SCRIPT_DIR"
    if source "$SCRIPT_DIR/.profile" && [[ -n "${PROFILE_BSP_COMMIT:-}" ]] && [[ "$(git rev-parse HEAD)" != "$PROFILE_BSP_COMMIT" ]]
    then
        echo "Profile was exported when bsp is at commit $PROFILE_BSP_COMMIT."
        echo "You can use 'git switch -d $PROFILE_BSP_COMMIT' to ensure the best compatability."
    fi
    popd
}

_install() {
    local disk="$1" file="${2:-}" i
    local ext="${file##*.}"

    if [[ -f "$disk" ]]
    then
        trap "set +e; sudo -n true && (sudo umount -R /mnt; sudo kpartx -d '$disk'; sync)" SIGINT SIGQUIT SIGTSTP EXIT
        sudo kpartx -a "$disk"
        disk="$(sudo blkid -t LABEL=rootfs -o device | grep /dev/mapper/loop | tail -n 1)"
        disk="${disk%p*}p"
    fi

    if [[ ! -b "$disk" ]] && [[ "$disk" != /dev/mapper/loop* ]]
    then
        error $EXIT_BAD_BLOCK_DEVICE "$disk"
    fi

    if [[ -n "$file" ]] && [[ ! -f "$file" ]]
    then
        error $EXIT_BAD_FILE "$file"
    fi

    sudo umount -R /mnt || true

    if [[ -b "$disk"3 ]]
    then
        # latest rbuild image
        sudo mount "$disk"3 /mnt
        sudo mount "$disk"2 /mnt/boot/efi
        sudo mount "$disk"1 /mnt/config
    elif [[ -b "$disk"2 ]]
    then
        sudo mount "$disk"2 /mnt
        case "$(sudo blkid "$disk"1 -s LABEL -o value)"
        in
            "armbi_boot")
                # new armbian image
                sudo mount "$disk"1 /mnt/boot
                ;;
            *)
                # old rbuild image
                sudo mount "$disk"1 /mnt/config
                ;;
        esac
    elif [[ -b "$disk"1 ]]
    then
        # old armbian image
        sudo mount "$disk"1 /mnt
    else
        error $EXIT_BAD_BLOCK_DEVICE "$disk"2
    fi

    case "$ext" in
        deb)
            sudo cp "$file" /mnt
            sudo systemd-nspawn -D /mnt bash -c \
                "dpkg -i '/$(basename "$file")' && \
                apt-get install -y --fix-missing  --allow-downgrades"
            ;;
        dtbo)
            sudo cp "$file" /mnt/boot/dtbo
            sudo systemd-nspawn -D /mnt u-boot-update
            ;;
        dtb)
            sudo find /mnt/usr/lib/linux-image-*/ -name "$(basename "$file")" -exec mv "{}" "{}.bak" \; -exec cp "$file" "{}" \;
            ;;
        "")
            if [[ -z "$file" ]]
            then
                sudo systemd-nspawn -D /mnt
            else
                error $EXIT_UNSUPPORTED_OPTION "$file"
            fi
            ;;
        *)
            error $EXIT_UNSUPPORTED_OPTION "$file"
            ;;
    esac
    
    sudo umount -R /mnt

    sync
}

bsp_reset() {
    BSP_ARCH="arm"
    BSP_GIT=
    BSP_TAG=
    BSP_COMMIT=
    BSP_BRANCH=
    BSP_DEFCONFIG=

    BSP_MAKE_DEFINES=()
    BSP_MAKE_TARGETS=("all")
    BSP_MAKE_EXTRA=()
    BSP_SOC=
    BSP_SOC_OVERRIDE=
    BSP_BL31_OVERRIDE=
    BSP_TRUST_OVERRIDE=
    BSP_BOARD_OVERRIDE=

    RKBIN_DDR=
    RKMINILOADER=
}

bsp_version() {
    make -C "$TARGET_DIR" -s ubootversion
}

bsp_prepare() {
    local soc_family=$(get_soc_family $BSP_SOC)

    BSP_SOC_OVERRIDE="${BSP_SOC_OVERRIDE:-"$BSP_SOC"}"
    BSP_BL31_OVERRIDE="${BSP_BL31_OVERRIDE:-"$BSP_SOC"}"
    BSP_TRUST_OVERRIDE="${BSP_TRUST_OVERRIDE:-"$BSP_SOC"}"
    BSP_BOARD_OVERRIDE="${BSP_BOARD_OVERRIDE:-"$BOARD"}"

    if [[ -z $BSP_DEFCONFIG ]]
    then
        case "$soc_family" in
            rockchip)
                BSP_DEFCONFIG="${BSP_BOARD_OVERRIDE}-${BSP_SOC}_defconfig"
                ;;
            *)
                BSP_DEFCONFIG="${BOARD}_defconfig"
                ;;
        esac
    fi

    case "$soc_family" in
        amlogic)
            if [[ $USE_ATF == "yes" ]]
            then
                make -C "$SCRIPT_DIR/.src/arm-trusted-firmware" -j$(nproc) CROSS_COMPILE=$CROSS_COMPILE PLAT=$BSP_BL31_OVERRIDE
            fi
            ;;
        rockchip)
            if [[ $USE_ATF == "yes" ]]
            then
                make -C "$SCRIPT_DIR/.src/arm-trusted-firmware" -j$(nproc) CROSS_COMPILE=$CROSS_COMPILE PLAT=$BSP_BL31_OVERRIDE
                BSP_MAKE_EXTRA+=("BL31=$SCRIPT_DIR/.src/arm-trusted-firmware/build/$BSP_BL31_OVERRIDE/release/bl31/bl31.elf")
            else
                local rkbin_bl31=$(find $SCRIPT_DIR/.src/rkbin/bin | grep -e ${BSP_BL31_OVERRIDE}_bl31_v | sort | tail -n 1)
                if [[ -z $rkbin_bl31 ]]
                then
                    echo "Unable to find prebuilt bl31. The resulting bootloader may not work!" >&2
                else
                    echo "Using bl31 $(basename $rkbin_bl31)"
                    BSP_MAKE_EXTRA+=("BL31=$rkbin_bl31")
                fi
            fi
            ;;
    esac
}

bsp_make() {
    make -C "$TARGET_DIR" -j$(nproc) \
        ARCH=$BSP_ARCH CROSS_COMPILE=$CROSS_COMPILE \
        UBOOTVERSION=$FORK-$(bsp_version)-$PKG_REVISION-$SOURCE_GITREV \
        "${BSP_MAKE_EXTRA[@]}" $@
}

rkpack_idbloader() {
    local flash_data=
    if [[ -n $RKBIN_DDR ]]
    then
        flash_data="$(find $SCRIPT_DIR/.src/rkbin/bin | grep ${RKBIN_DDR} | sort | tail -n 1)"
        if [[ -z $flash_data ]]
        then
            error $EXIT_UNKNOWN_OPTION "$RKBIN_DDR"
        else
            echo "Using rkbin $(basename $flash_data)"
        fi
    fi

    if [[ -e "${SCRIPT_DIR}/.src/u-boot/spl/u-boot-spl.bin" ]] && [[ "$1" == "spl" ]]
    then
        flash_data="${flash_data:+${flash_data}:}${SCRIPT_DIR}/.src/u-boot/spl/u-boot-spl.bin"
    fi

    $TARGET_DIR/tools/mkimage -n $BSP_SOC_OVERRIDE -T rksd -d "${flash_data}" "$TARGET_DIR/idbloader.img"
    $TARGET_DIR/tools/mkimage -n $BSP_SOC_OVERRIDE -T rkspi -d "${flash_data}" "$TARGET_DIR/idbloader-spi.img"

    if [[ "$1" == "rkminiloader" ]]
    then
        local flash_data="$(find $SCRIPT_DIR/.src/rkbin/bin | grep ${RKMINILOADER} | sort | tail -n 1)"
        if [[ -z $flash_data ]]
        then
            error $EXIT_UNKNOWN_OPTION "$RKMINILOADER"
        else
            echo "Using rkminiloader $(basename $flash_data)"
            cat "$flash_data" >> "$TARGET_DIR/idbloader.img"
            cat "$flash_data" >> "$TARGET_DIR/idbloader-spi.img"
        fi
    fi
}

rkpack_rkminiloader() {
    pushd $SCRIPT_DIR/.src/rkbin/
    $SCRIPT_DIR/.src/rkbin/tools/loaderimage --pack --uboot "$TARGET_DIR/u-boot-dtb.bin" "$TARGET_DIR/uboot.img"
    $SCRIPT_DIR/.src/rkbin/tools/trust_merger "$SCRIPT_DIR/.src/rkbin/RKTRUST/${BSP_TRUST_OVERRIDE^^}TRUST.ini"
    mv ./trust.img "$TARGET_DIR/trust.img"
    popd

    cp "$TARGET_DIR/uboot.img" "$TARGET_DIR/trust.img" "$SCRIPT_DIR/.root/usr/lib/u-boot-$BSP_BOARD_OVERRIDE/"
}

rkpack_rkboot() {
    pushd $SCRIPT_DIR/.src/rkbin/
    rm -f ./*.bin
    $SCRIPT_DIR/.src/rkbin/tools/boot_merger "$SCRIPT_DIR/.src/rkbin/RKBOOT/${BSP_TRUST_OVERRIDE^^}MINIALL.ini"
    mv ./*.bin "$SCRIPT_DIR/.root/usr/lib/u-boot-$BSP_BOARD_OVERRIDE/rkboot.bin"
    popd
}

bsp_preparedeb() {
    local soc_family=$(get_soc_family $BSP_SOC)
    
    mkdir -p "$SCRIPT_DIR/.root/usr/lib/u-boot-$BSP_BOARD_OVERRIDE"
    cp "$SCRIPT_DIR/common/u-boot_setup.sh" "$SCRIPT_DIR/.root/usr/lib/u-boot-$BSP_BOARD_OVERRIDE/setup.sh"

    case "$soc_family" in
        amlogic)
            make -C "$SCRIPT_DIR/.src/fip" -j$(nproc) distclean
            make -C "$SCRIPT_DIR/.src/fip" -j$(nproc) fip BOARD=$BSP_BOARD_OVERRIDE UBOOT_BIN="$TARGET_DIR/u-boot.bin"

            cp "$SCRIPT_DIR/.src/fip/$BSP_BOARD_OVERRIDE/u-boot.bin" "$SCRIPT_DIR/.src/fip/$BSP_BOARD_OVERRIDE/u-boot.bin.sd.bin" "$SCRIPT_DIR/.root/usr/lib/u-boot-$BSP_BOARD_OVERRIDE/"
            ;;
        rockchip)
            if [[ -z "$RKMINILOADER" ]]
            then
                echo "No RKMINILOADER specified. Require prepacked u-boot.itb."
                rkpack_idbloader "spl"
                cp "$TARGET_DIR/u-boot.itb" "$SCRIPT_DIR/.root/usr/lib/u-boot-$BSP_BOARD_OVERRIDE/"
            else
                echo "Packaging U-Boot with Rockchip Miniloader"
                rkpack_idbloader "rkminiloader"
                rkpack_rkminiloader
            fi
            rkpack_rkboot
            cp "$TARGET_DIR/idbloader-spi.img" "$TARGET_DIR/idbloader.img" "$SCRIPT_DIR/.root/usr/lib/u-boot-$BSP_BOARD_OVERRIDE/"
            ;;
        *)
            error $EXIT_UNSUPPORTED_OPTION "$soc_family"
            ;;
    esac
}

bsp_makedeb() {
    local NAME="u-boot-$FORK"
    local VERSION="$(bsp_version)-$PKG_REVISION-$SOURCE_GITREV"
    local URL="https://github.com/radxa-pkg/$NAME"
    local DESCRIPTION="Radxa U-Boot image for $FORK"
    fpm -s dir -t deb -n "$NAME" -v "$VERSION" \
        --deb-compression xz \
        -a arm64 \
        --depends dthelper \
        --url "$URL" \
        --description "$DESCRIPTION" \
        --license "GPL-2+" \
        -m "Radxa <dev@radxa.com>" \
        --vendor "Radxa" \
        --force \
        "$SCRIPT_DIR/.root/"=/

    local VERSION="$(bsp_version)-$PKG_REVISION-$BSP_GITREV"
    for BOARD in ${SUPPORTED_BOARDS[@]}
    do
        local NAME="u-boot-$BOARD"
        local DESCRIPTION="Radxa virtual U-Boot package for $BOARD"
        local DEPEND=u-boot-$FORK
        local CONFLICT=
        if [[ $BOARD != $BSP_BOARD_OVERRIDE ]]
        then
            CONFLICT="--conflicts u-boot-$BSP_BOARD_OVERRIDE"
        fi
        fpm -s empty -t deb -n "$NAME" -v "$VERSION" \
            --deb-compression xz \
            --depends "$DEPEND" \
            $CONFLICT \
            --url "$URL" \
            --description "$DESCRIPTION" \
            --license "GPL-2+" \
            -m "Radxa <dev@radxa.com>" \
            --vendor "Radxa" \
            --force
    done
}
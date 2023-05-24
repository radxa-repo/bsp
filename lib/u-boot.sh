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
    BSP_BL31_VARIANT=
    BSP_TRUST_OVERRIDE=
    BSP_BOARD_OVERRIDE=
    BSP_ROCKCHIP_TPL=
    BSP_RKMINILOADER=
    BSP_RKMINILOADER_SPINOR=
    BSP_RKMINILOADER_SPINAND=

    RKBIN_DDR=
    RKMINILOADER=
    UBOOT_BASE_ADDR=
    USE_ATF="false"
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
            if $USE_ATF
            then
                make -C "$SCRIPT_DIR/.src/arm-trusted-firmware" -j$(nproc) CROSS_COMPILE=$CROSS_COMPILE PLAT=$BSP_BL31_OVERRIDE
            fi
            ;;
        rockchip)
            if $USE_ATF
            then
                make -C "$SCRIPT_DIR/.src/arm-trusted-firmware" -j$(nproc) CROSS_COMPILE=$CROSS_COMPILE PLAT=$BSP_BL31_OVERRIDE
                BSP_MAKE_EXTRA+=("BL31=$SCRIPT_DIR/.src/arm-trusted-firmware/build/$BSP_BL31_OVERRIDE/release/bl31/bl31.elf")
            else
                local rkbin_bl31
                if [[ -n $BSP_BL31_OVERRIDE ]]
                then
                    rkbin_bl31=$(find $SCRIPT_DIR/.src/rkbin/bin | grep -e "${BSP_BL31_OVERRIDE}_bl31_${BSP_BL31_VARIANT:-v}" | sort | tail -n 1)
                    if [[ -z $rkbin_bl31 ]]
                    then
                        echo "Unable to find prebuilt bl31. The resulting bootloader may not work!" >&2
                    else
                        echo "Using bl31 $(basename $rkbin_bl31)"
                        BSP_MAKE_EXTRA+=("BL31=$rkbin_bl31")
                    fi
                fi

                if [[ -n $RKBIN_DDR ]]
                then
                    BSP_ROCKCHIP_TPL="$(find $SCRIPT_DIR/.src/rkbin/bin | grep ${RKBIN_DDR} | sort | tail -n 1)"
                    if [[ -z $BSP_ROCKCHIP_TPL ]]
                    then
                        echo "Unable to find prebuilt Rockchip TPL. The resulting bootloader may not work!" >&2
                    else
                        echo "Using Rockchip TPL $(basename $BSP_ROCKCHIP_TPL)"
                        BSP_MAKE_EXTRA+=("ROCKCHIP_TPL=$BSP_ROCKCHIP_TPL")
                    fi
                fi

                if [[ -n $RKMINILOADER ]]
                then
                    if ! BSP_RKMINILOADER=$(find $SCRIPT_DIR/.src/rkbin/bin | grep ${RKMINILOADER}v | sort | tail -n 1) || [[ -z $BSP_RKMINILOADER ]]
                    then
                        echo "Unable to find Rockchip miniloader. The resulting bootloader may not work!" >&2
                    else
                        echo "Using Rockchip miniloader $(basename $BSP_RKMINILOADER)"
                    fi

                    if ! BSP_RKMINILOADER_SPINOR=$(find $SCRIPT_DIR/.src/rkbin/bin | grep ${RKMINILOADER}spinor_v | sort | tail -n 1) || [[ -z $BSP_RKMINILOADER_SPINOR ]]
                    then
                        echo "Unable to find Rockchip SPI NOR miniloader. This is only required for some platforms." >&2
                    else
                        echo "Using Rockchip SPI NOR miniloader $(basename $BSP_RKMINILOADER_SPINOR)"
                    fi

                    if ! BSP_RKMINILOADER_SPINAND=$(find $SCRIPT_DIR/.src/rkbin/bin | grep ${RKMINILOADER}spinand_v | sort | tail -n 1) || [[ -z $BSP_RKMINILOADER_SPINAND ]]
                    then
                        echo "Unable to find Rockchip miniloader for SPI NAND. This is only required for all platforms." >&2
                    else
                        echo "Using Rockchip SPI NAND miniloader $(basename $BSP_RKMINILOADER_SPINAND)"
                    fi
                fi
            fi
            ;;
    esac
}

bsp_make() {
    # To enable debug log, add the following line below:
    #   KCPPFLAGS=-DLOG_DEBUG \
    make -C "$TARGET_DIR" -j$(nproc) \
        ARCH=$BSP_ARCH CROSS_COMPILE=$CROSS_COMPILE \
        UBOOTVERSION=$FORK-$(bsp_version)-${PKG_REVISION}${SOURCE_GITREV:+-$SOURCE_GITREV} \
        "${BSP_MAKE_EXTRA[@]}" $@
}

rkpack_idbloader() {
    local flash_data=
    if [[ -n $BSP_ROCKCHIP_TPL ]]
    then
        echo "Using rkbin $(basename $BSP_ROCKCHIP_TPL) as TPL"
        flash_data="$BSP_ROCKCHIP_TPL"
    elif [[ -e "${SCRIPT_DIR}/.src/u-boot/tpl/u-boot-tpl.bin" ]] && [[ "$1" == "spl" ]]
    then
        echo "Using U-Boot TPL"
        flash_data="${SCRIPT_DIR}/.src/u-boot/tpl/u-boot-tpl.bin"
    fi

    if [[ -e "${SCRIPT_DIR}/.src/u-boot/spl/u-boot-spl.bin" ]] && [[ "$1" == "spl" ]]
    then
        flash_data="${flash_data:+${flash_data}:}${SCRIPT_DIR}/.src/u-boot/spl/u-boot-spl.bin"
    fi

    rm -f "$TARGET_DIR/idbloader.img" "$TARGET_DIR/idbloader-spi.img" "$TARGET_DIR/idbloader-spi_spl.img"
    $TARGET_DIR/tools/mkimage -n $BSP_SOC_OVERRIDE -T rksd -d "${flash_data}" "$TARGET_DIR/idbloader.img"

    if [[ "$1" == "rkminiloader" ]]
    then
        echo "Using rkminiloader $(basename $BSP_RKMINILOADER)"
        cat "$BSP_RKMINILOADER" >> "$TARGET_DIR/idbloader.img"

        if [[ -n $BSP_RKMINILOADER_SPINOR ]]
        then
            $TARGET_DIR/tools/mkimage -n $BSP_SOC_OVERRIDE -T rkspi -d "${flash_data:+${flash_data}:}$BSP_RKMINILOADER_SPINOR" "$TARGET_DIR/idbloader-spi.img"
        fi
    else
        if [[ "$BSP_SOC_OVERRIDE" =~ "rk3399" ]]
        then
            $TARGET_DIR/tools/mkimage -n $BSP_SOC_OVERRIDE -T rkspi -d "${flash_data}" "$TARGET_DIR/idbloader-spi_spl.img"
        fi
    fi
}

rkpack_rkminiloader() {
    pushd $SCRIPT_DIR/.src/rkbin/
    $SCRIPT_DIR/.src/rkbin/tools/loaderimage --pack --uboot "$TARGET_DIR/u-boot-dtb.bin" "$TARGET_DIR/uboot.img" ${UBOOT_BASE_ADDR} --size 1024 1
    $SCRIPT_DIR/.src/rkbin/tools/trust_merger --size 1024 1 "$SCRIPT_DIR/.src/rkbin/RKTRUST/${BSP_TRUST_OVERRIDE^^}TRUST.ini"
    mv ./trust.img "$TARGET_DIR/trust.img"
    popd

    cp "$TARGET_DIR/uboot.img" "$TARGET_DIR/trust.img" "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/"
}

rkpack_rkboot() {
    pushd $SCRIPT_DIR/.src/rkbin/
    rm -f ./*.bin
    local variant
    for variant in "" "_SPINOR" "_SPI_NAND"
    do
        if [[ -f "$SCRIPT_DIR/.src/rkbin/RKBOOT/${BSP_TRUST_OVERRIDE^^}MINIALL$variant.ini" ]]
        then
            $SCRIPT_DIR/.src/rkbin/tools/boot_merger "$SCRIPT_DIR/.src/rkbin/RKBOOT/${BSP_TRUST_OVERRIDE^^}MINIALL$variant.ini"
            mv ./*_loader_*.bin "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/rkboot$variant.bin"
        fi
    done
    popd
}

bsp_preparedeb() {
    local soc_family=$(get_soc_family $BSP_SOC)
    
    mkdir -p "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE"
    cp "$SCRIPT_DIR/common/u-boot_setup-$soc_family.sh" "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/setup.sh"

    case "$soc_family" in
        amlogic)
            make -C "$SCRIPT_DIR/.src/fip" -j$(nproc) distclean
            make -C "$SCRIPT_DIR/.src/fip" -j$(nproc) fip BOARD=$BSP_BOARD_OVERRIDE UBOOT_BIN="$TARGET_DIR/u-boot.bin"

            cp "$SCRIPT_DIR/.src/fip/$BSP_BOARD_OVERRIDE/u-boot.bin" "$SCRIPT_DIR/.src/fip/$BSP_BOARD_OVERRIDE/u-boot.bin.sd.bin" "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/"
            ;;
        rockchip)
            if [[ -z "$RKMINILOADER" ]]
            then
                echo "No RKMINILOADER specified. Require prepacked u-boot.itb."
                rkpack_idbloader "spl"
                cp "$TARGET_DIR/u-boot.itb" "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/"
            else
                echo "Packaging U-Boot with Rockchip Miniloader"
                rkpack_idbloader "rkminiloader"
                rkpack_rkminiloader
            fi
            rkpack_rkboot
            cp "$TARGET_DIR/idbloader-spi"*".img" "$TARGET_DIR/idbloader.img" "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/"
            ;;
        *)
            error $EXIT_UNSUPPORTED_OPTION "$soc_family"
            ;;
    esac
}

bsp_makedeb() {
    local NAME="u-boot-$FORK"
    local VERSION="$(bsp_version)-${PKG_REVISION}${SOURCE_GITREV:+-$SOURCE_GITREV}"
    local URL="https://github.com/radxa-pkg/$NAME"
    local DESCRIPTION="Radxa U-Boot image for $FORK"
    fpm -s dir -t deb -n "$NAME" -v "$VERSION" \
        --deb-compression xz \
        -a arm64 \
        --url "$URL" \
        --description "$DESCRIPTION" \
        --license "GPL-2+" \
        -m "Radxa <dev@radxa.com>" \
        --vendor "Radxa" \
        --force \
        "$SCRIPT_DIR/.root/"=/

    local VERSION="$(bsp_version)-${PKG_REVISION}${BSP_GITREV:+-$BSP_GITREV}"
    for BOARD in ${SUPPORTED_BOARDS[@]}
    do
        local NAME="u-boot-$BOARD"
        local DESCRIPTION="Radxa U-Boot meta-package for $BOARD"
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
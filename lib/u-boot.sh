bsp_reset() {
    BSP_ARCH="arm"
    BSP_GIT=
    BSP_TAG=
    BSP_COMMIT=
    BSP_BRANCH=
    BSP_DEFCONFIG=
    BSP_REPLACES=

    BSP_MAKE_DEFINES=()
    BSP_MAKE_TARGETS=("all")
    BSP_MAKE_EXTRA=()
    BSP_SOC=
    BSP_SOC_OVERRIDE=
    BSP_BL31_OVERRIDE=
    BSP_BL31_VARIANT=
    BSP_BL32_OVERRIDE=
    BSP_BL32_VARIANT=
    BSP_TRUST_OVERRIDE=
    BSP_BOARD_OVERRIDE=
    BSP_ROCKCHIP_TPL=
    BSP_RKMINILOADER=
    BSP_RKMINILOADER_SPINOR=
    BSP_RKMINILOADER_SPINAND=
    BSP_RKMINILOADER_SDNAND=

    RKBIN_DDR=
    RKMINILOADER=
    UBOOT_BASE_ADDR=
    RKBOOT_IDB=
    USE_ATF="false"

    BSP_MTK_LK_PROJECT=
    BSP_MTK_LIBDRAM_BOARD_NAME=
    BSP_OPTEE_DRAM_SIZE=
    BSP_UFS_BOOT="false"
}

bsp_version() {
    make -C "$TARGET_DIR" -s ubootversion
}

bsp_prepare() {
    local soc_family=$(get_soc_family $BSP_SOC)

    BSP_SOC_OVERRIDE="${BSP_SOC_OVERRIDE:-"$BSP_SOC"}"
    BSP_BL31_OVERRIDE="${BSP_BL31_OVERRIDE:-"$BSP_SOC"}"
    BSP_BL32_OVERRIDE="${BSP_BL32_OVERRIDE:-"$BSP_SOC"}"
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
                    if ! rkbin_bl31=$(find $SCRIPT_DIR/.src/rkbin/bin | grep -e "${BSP_BL31_OVERRIDE}_bl31_${BSP_BL31_VARIANT:-v}" | sort | tail -n 1) || [[ -z $rkbin_bl31 ]]
                    then
                        echo "Unable to find prebuilt bl31. The resulting bootloader will not work!" >&2
                        return 1
                    else
                        echo "Using bl31 $(basename $rkbin_bl31)"
                        BSP_MAKE_EXTRA+=("BL31=$rkbin_bl31")
                    fi
                fi

                local rkbin_bl32
                if [[ -n $BSP_BL32_OVERRIDE ]]
                then
                    if ! rkbin_bl32=$(find $SCRIPT_DIR/.src/rkbin/bin | grep -e "${BSP_BL32_OVERRIDE}_bl32_${BSP_BL32_VARIANT}" | sort | tail -n 1) || [[ -z $rkbin_bl32 ]]
                    then
                        echo "Unable to find prebuilt bl32. The resulting bootloader may not work." >&2
                    else
                        echo "Using bl32 $(basename $rkbin_bl32)"
                        ln -sf "$rkbin_bl32" "$SCRIPT_DIR/.src/u-boot/tee.bin"
                    fi
                else
                    rm -f "$SCRIPT_DIR/.src/u-boot/tee.bin"
                fi

                if [[ -n $RKBIN_DDR ]]
                then
                    if ! BSP_ROCKCHIP_TPL="$(find $SCRIPT_DIR/.src/rkbin/bin | grep ${RKBIN_DDR} | sort | tail -n 1)" || [[ -z $BSP_ROCKCHIP_TPL ]]
                    then
                        echo "Unable to find prebuilt Rockchip TPL. The resulting bootloader may not work!" >&2
                    else
                        echo "Using Rockchip TPL $(basename $BSP_ROCKCHIP_TPL)"
                        BSP_MAKE_EXTRA+=("ROCKCHIP_TPL=$BSP_ROCKCHIP_TPL")
                    fi
                fi

                if [[ -n $RKMINILOADER ]]
                then
                    if BSP_RKMINILOADER="$(find $SCRIPT_DIR/.src/rkbin/bin -name ${RKMINILOADER})" && [[ -n "$BSP_RKMINILOADER" ]] && [[ "$(basename $BSP_RKMINILOADER)" == "${RKMINILOADER}" ]]
                    then
                        echo "Using Rockchip miniloader $(basename $BSP_RKMINILOADER) with exact match"
                    elif ! BSP_RKMINILOADER=$(find $SCRIPT_DIR/.src/rkbin/bin | grep ${RKMINILOADER}v | sort | tail -n 1) || [[ -z $BSP_RKMINILOADER ]]
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
                        echo "Unable to find Rockchip miniloader for SPI NAND. This is only required for some platforms." >&2
                    else
                        echo "Using Rockchip SPI NAND miniloader $(basename $BSP_RKMINILOADER_SPINAND)"
                    fi

                    if ! BSP_RKMINILOADER_SDNAND=$(find $SCRIPT_DIR/.src/rkbin/bin | grep ${RKMINILOADER}v | grep sd.bin | sort | tail -n 1) || [[ -z $BSP_RKMINILOADER_SDNAND ]]
                    then
                        echo "Unable to find Rockchip miniloader for SD NAND. This is only required for some platforms." >&2
                    else
                        echo "Using Rockchip SD NAND miniloader $(basename $BSP_RKMINILOADER_SDNAND)"
                    fi
                fi
            fi
            ;;
        mediatek)
            make -C "$SCRIPT_DIR/.src/mtk-optee" -j$(nproc) \
                CROSS_COMPILE_core=$CROSS_COMPILE \
                CROSS_COMPILE_ta_arm64=$CROSS_COMPILE \
                PLATFORM=mediatek \
                CFG_DRAM_SIZE=$BSP_OPTEE_DRAM_SIZE \
                CFG_TZDRAM_START=0x43200000 \
                CFG_TZDRAM_SIZE=0x00a00000 \
                SOC_PLATFORM=$BSP_BL31_OVERRIDE \
                CFG_TEE_CORE_LOG_LEVEL=3 CFG_UART_ENABLE=y \
                CFG_ARM64_core=y \
                ta-targets=ta_arm64
                #CONSOLE_BAUDRATE=115200

            local atf_extra_option=()
            if "$BSP_UFS_BOOT"
            then
                atf_extra_option+=("STORAGE_UFS=1")
            fi

            make -C "$SCRIPT_DIR/.src/mtk-atf" -j$(nproc) CROSS_COMPILE=$CROSS_COMPILE \
                E=0 "${atf_extra_option[@]}" \
                PLAT=$BSP_BL31_OVERRIDE \
                TFA_PLATFORM=$BSP_BL31_OVERRIDE \
                TFA_SPD=opteed \
                LIBDRAM=$SCRIPT_DIR/.src/libdram-prebuilt/$BSP_MTK_LIBDRAM_BOARD_NAME/libdram.a \
                LIBBASE=$SCRIPT_DIR/.src/libbase-prebuilt/$BSP_BL31_OVERRIDE/libbase.a \
                NEED_BL32=yes CFLAGS+=-DNEED_BL32\
                BL32=$SCRIPT_DIR/.src/mtk-optee/out/arm-plat-mediatek/core/tee.bin
                #NEED_BL33=yes \
                #BL33=$SCRIPT_DIR/.src/u-boot/u-boot.bin

            BSP_MAKE_EXTRA+=("BL31=$SCRIPT_DIR/.src/mtk-atf/build/$BSP_BL31_OVERRIDE/release/bl31/bl31.elf")
            ;;
        *)
            error $EXIT_UNSUPPORTED_OPTION "$soc_family"
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
    if [[ -n $RKBOOT_IDB ]]
    then
        echo "Skip rkpack_idbloader. idbloader will be created by rkpack_rkboot."
        return
    fi
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

    $TARGET_DIR/tools/mkimage -n $BSP_SOC_OVERRIDE -T rksd -d "${flash_data}" "$TARGET_DIR/idbloader.img"

    if [[ "$1" == "rkminiloader" ]]
    then
        echo "Using rkminiloader $(basename $BSP_RKMINILOADER)"
        cat "$BSP_RKMINILOADER" >> "$TARGET_DIR/idbloader.img"

        if [[ -n $BSP_RKMINILOADER_SPINOR ]]
        then
            echo "Using Rockchip SPI NOR miniloader $(basename $BSP_RKMINILOADER_SPINOR)"
            if [[ "$BSP_SOC_OVERRIDE" =~ "rk3399" ]] && [[ "$BSP_BRANCH" == "rk3399-pie-gms-express-baseline" ]]
            then
                # mkimage in this branch is too old to support multiple data file
                mkimage -n $BSP_SOC_OVERRIDE -T rkspi -d "${flash_data:+${flash_data}:}$BSP_RKMINILOADER_SPINOR" "$TARGET_DIR/idbloader-spi.img"
            else
                $TARGET_DIR/tools/mkimage -n $BSP_SOC_OVERRIDE -T rkspi -d "${flash_data:+${flash_data}:}$BSP_RKMINILOADER_SPINOR" "$TARGET_DIR/idbloader-spi.img"
            fi
        fi

        if [[ -n $BSP_RKMINILOADER_SDNAND ]]
        then
            echo "Using Rockchip SD NAND miniloader $(basename $BSP_RKMINILOADER_SDNAND)"
            $TARGET_DIR/tools/mkimage -n $BSP_SOC_OVERRIDE -T rksd -d "${flash_data}" "$TARGET_DIR/idbloader-sd_nand.img"
            cat "$BSP_RKMINILOADER_SDNAND" >> "$TARGET_DIR/idbloader-sd_nand.img"
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
    for variant in "" "_SPINOR" "_SPI_NAND" "_UART0_SD_NAND"
    do
        local rkboot_ini="$SCRIPT_DIR/.src/rkbin/RKBOOT/${BSP_TRUST_OVERRIDE^^}MINIALL$variant.ini"

        if [[ ! -f $rkboot_ini ]]
        then
            continue
        fi

        if [[ -n $RKBOOT_IDB ]]
        then
            sed -i "s|FlashBoot=.*$|FlashBoot=${SCRIPT_DIR}/.src/u-boot/spl/u-boot-spl.bin|g" "$rkboot_ini"
        fi

        $SCRIPT_DIR/.src/rkbin/tools/boot_merger "$rkboot_ini"
        mv ./*_loader_*.bin "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/rkboot$variant.bin"

        if [[ -n $RKBOOT_IDB ]]
        then
            local idb_variant
            case "$variant" in
                "_SPINOR")
                    idb_variant="-spi_spl"
                    ;;
                "_SPI_NAND")
                    idb_variant="-spi_nand"
                    ;;
                "_UART0_SD_NAND")
                    idb_variant="-sd_nand"
                    ;;
                "")
                    idb_variant=""
                    ;;
            esac
            mv ./"$RKBOOT_IDB"* "$TARGET_DIR/idbloader$idb_variant.img"
        fi
    done
    popd
}

bsp_preparedeb() {
    local soc_family=$(get_soc_family $BSP_SOC)
    
    mkdir -p "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE"
    cp "$SCRIPT_DIR/common/u-boot_setup-$soc_family.sh" "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/setup.sh"
    if [[ -f "$SCRIPT_DIR/common/u-boot_setup-$soc_family.ps1" ]]; then
        cp "$SCRIPT_DIR/common/u-boot_setup-$soc_family.ps1" "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/setup.ps1"
    fi

    case "$soc_family" in
        amlogic)
            make -C "$SCRIPT_DIR/.src/fip" -j$(nproc) distclean
            make -C "$SCRIPT_DIR/.src/fip" -j$(nproc) fip BOARD=$BSP_BOARD_OVERRIDE UBOOT_BIN="$TARGET_DIR/u-boot.bin"

            cp "$SCRIPT_DIR/.src/fip/$BSP_BOARD_OVERRIDE/u-boot.bin" "$SCRIPT_DIR/.src/fip/$BSP_BOARD_OVERRIDE/u-boot.bin.sd.bin" "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/"
            ;;
        rockchip)
            rm -f "$TARGET_DIR/idbloader.img" "$TARGET_DIR/idbloader-spi.img" "$TARGET_DIR/idbloader-spi_spl.img" "$TARGET_DIR/idbloader-sd_nand.img"
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
            cp "$TARGET_DIR/idbloader-spi"*".img" "$TARGET_DIR/idbloader-sd"*".img" "$TARGET_DIR/idbloader.img" "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/"
            ;;
        mediatek)
            cp "$SCRIPT_DIR/.src/mtk-atf/build/$BSP_BL31_OVERRIDE/release/bl2.bin" "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/"
            truncate -s%4 "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/bl2.bin"

            local media="emmc"
            if "$BSP_UFS_BOOT"
            then
                media="ufs"
            fi
            "$TARGET_DIR/tools/mkimage" -T mtk_image -a 0x201000 -e 0x201000 -n "media=$media;arm64=1" \
                -d "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/bl2.bin" \
                "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/bl2.img"
            rm "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/bl2.bin"

            cp "$SCRIPT_DIR/.src/lk-prebuilt/$BSP_MTK_LK_PROJECT/lk.bin" "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/"

            cp "$TARGET_DIR/u-boot.bin" "$TARGET_DIR/u-boot-mtk.bin" "$SCRIPT_DIR/.root/usr/lib/u-boot/$BSP_BOARD_OVERRIDE/"
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
    local REPLACES=()
    if [[ -n "$BSP_REPLACES" ]]
    then
        REPLACES+=(
            "--provides" "u-boot-$BSP_REPLACES"
            "--conflicts" "u-boot-$BSP_REPLACES"
            "--replaces" "u-boot-$BSP_REPLACES"
        )
    fi
    fpm -s dir -t deb -n "$NAME" -v "$VERSION" \
        --deb-compression xz \
        -a arm64 \
        "${REPLACES[@]}" \
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

component_build() {
    if (( $# > 1 )) && [[ -n "$2" ]]
    then
        if ! in_array "$2" "${SUPPORTED_BOARDS[@]}"
        then
            error $EXIT_UNKNOWN_OPTION "$2"
        fi
        local products=("$2")
    else
        local products=("${SUPPORTED_BOARDS[@]}")
    fi

    rm -rf "$SCRIPT_DIR/.root"

    for BOARD in "${products[@]}"
    do
        load_profile u-boot "$1"

        if [[ $(type -t bsp_profile_base) == function ]]
        then
            bsp_profile_base
        fi
        if [[ $(type -t bsp_$BOARD) == function ]]
        then
            if [[ -f "$SCRIPT_DIR/$TARGET/$FORK/kconfig.template" ]]
            then
                rm -f "$SCRIPT_DIR/$TARGET/$FORK/kconfig.conf"
            fi
            bsp_$BOARD
        fi
        if [[ $(type -t bsp_profile_override) == function ]]
        then
            bsp_profile_override
        fi

        echo "Start building for $BOARD..."
        bsp_build
        bsp_preparedeb
        if $LONG_VERSION
        then
            SOURCE_GITREV_OVERRIDE="${SOURCE_GITREV_OVERRIDE:-$SOURCE_GITREV}"
        fi
    done

    SUPPORTED_BOARDS=("${products[@]}")
    if $LONG_VERSION
    then
        SOURCE_GITREV="$SOURCE_GITREV_OVERRIDE"
    fi
    bsp_makedeb
}

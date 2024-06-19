bsp_reset() {
    BSP_ARCH="arm64"
    BSP_GIT=
    BSP_TAG=
    BSP_COMMIT=
    BSP_BRANCH=
    BSP_DEFCONFIG="defconfig"

    BSP_MAKE_DEFINES=()
    BSP_MAKE_TARGETS=("olddefconfig" "all" "bindeb-pkg")
    BSP_DPKG_FLAGS="-d"
}

bsp_version() {
    make -C "$TARGET_DIR" -s kernelversion
}

bsp_prepare() {
    return
}

bsp_make() {
    local kernelversion="$(bsp_version)"

    make -C "$TARGET_DIR" -j$(nproc) \
        ARCH=$BSP_ARCH CROSS_COMPILE=$CROSS_COMPILE HOSTCC=${CROSS_COMPILE}gcc \
        KDEB_COMPRESS="xz" KDEB_CHANGELOG_DIST="unstable" DPKG_FLAGS=$BSP_DPKG_FLAGS \
        LOCALVERSION=-$PKG_REVISION-$FORK KERNELRELEASE=$kernelversion-$PKG_REVISION-$FORK KDEB_PKGVERSION=$kernelversion-${PKG_REVISION}${SOURCE_GITREV:+-$SOURCE_GITREV} \
        $@
}

bsp_makedeb() {
    local kernelversion="$(bsp_version)"

    mv $SCRIPT_DIR/.src/*.deb ./
    for BOARD in ${SUPPORTED_BOARDS[@]}
    do
        local NAMES=("linux-image-$BOARD" "linux-headers-$BOARD" "linux-libc-dev-$BOARD")
        local DESCRIPTIONS=("Radxa Linux meta-package for $BOARD" "Radxa Linux header meta-package for $BOARD" "Radxa userspace header meta-package for $BOARD")
        local DEPENDS=("linux-image-$kernelversion-$PKG_REVISION-$FORK" "linux-headers-$kernelversion-$PKG_REVISION-$FORK" "linux-libc-dev-$kernelversion-$PKG_REVISION-$FORK")
        local PROVIDES=("linux-image" "linux-headers" "linux-libc-dev")
        for i in {0..2}
        do
            local NAME=${NAMES[$i]}
            local VERSION="$kernelversion-${PKG_REVISION}${BSP_GITREV:+-$BSP_GITREV}"
            local URL="https://github.com/radxa-pkg/linux-image-$FORK"
            local DESCRIPTION=${DESCRIPTIONS[$i]}
            local DEPEND=("--depends" "${DEPENDS[$i]}")
            if (( i == 0 ))
            then
                # Linux image also requires the overlay package
                DEPEND+=("--depends" "radxa-overlays-dkms")
            fi
            local PROVIDE=()
            if [[ -n "${PROVIDES[$i]}" ]]
            then
                PROVIDE=("--provides" "${PROVIDES[$i]}")
            fi
            fpm -s empty -t deb -n "$NAME" -v "$VERSION" \
                --deb-compression xz \
                "${DEPEND[@]}" \
                "${PROVIDE[@]}" \
                --url "$URL" \
                --description "$DESCRIPTION" \
                --license "GPL-2+" \
                -m "Radxa <dev@radxa.com>" \
                --vendor "Radxa" \
                --force
        done
    done
}

component_build() {
    if $DTB_ONLY
    then
        BSP_MAKE_TARGETS=("dtbs")
        bsp_build
    else
        bsp_build
        bsp_makedeb
    fi
}

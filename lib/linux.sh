bsp_reset() {
    BSP_ARCH="arm64"
    BSP_GIT=
    BSP_TAG=
    BSP_COMMIT=
    BSP_BRANCH=
    BSP_DEFCONFIG="defconfig"

    BSP_MAKE_DEFINES=()
    BSP_MAKE_TARGETS=("all" "bindeb-pkg")
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
        ARCH=$BSP_ARCH CROSS_COMPILE=$CROSS_COMPILE \
        KDEB_COMPRESS="xz" KDEB_CHANGELOG_DIST="unstable" DPKG_FLAGS=$BSP_DPKG_FLAGS \
        LOCALVERSION=-$FORK KERNELRELEASE=$kernelversion-$FORK KDEB_PKGVERSION=$kernelversion-$PKG_REVISION-$SOURCE_GITREV \
        $@
}

bsp_makedeb() {
    local kernelversion="$(bsp_version)"

    mv $SCRIPT_DIR/.src/*.deb ./
    for BOARD in ${SUPPORTED_BOARDS[@]}
    do
        local NAMES=("linux-image-$BOARD" "linux-headers-$BOARD")
        local DESCRIPTIONS=("Radxa virtual Linux package for $BOARD" "Radxa virtual Linux header package for $BOARD")
        local DEPENDS=("linux-image-$kernelversion-$FORK" "linux-headers-$kernelversion-$FORK")
        for i in {0..1}
        do
            local NAME=${NAMES[$i]}
            local VERSION="$kernelversion-$PKG_REVISION-$BSP_GITREV"
            local URL="https://github.com/radxa-pkg/linux-image-$FORK"
            local DESCRIPTION=${DESCRIPTIONS[$i]}
            local DEPEND=${DEPENDS[$i]}
            fpm -s empty -t deb -n "$NAME" -v "$VERSION" \
                --deb-compression xz \
                --depends "$DEPEND" \
                --url "$URL" \
                --description "$DESCRIPTION" \
                --license "GPL-2+" \
                -m "Radxa <dev@radxa.com>" \
                --vendor "Radxa" \
                --force
        done
    done
}
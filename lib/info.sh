usage() {
    cat >&2 << EOF
Radxa BSP Build Tool
usage: $(basename "$0") [options] <linux|u-boot> <profile> [product]

When building u-boot, you can also provide 'product' argument,
which will only build for that specific image.

Supported package generation options:
    -r, --revision [num]    Specify custom revision number, default=1
    -c, --clean             Run 'make clean' before building
    -C, --distclean         Run 'make distclean' before building
    --no-prepare-source     Allow building against locally modified repos
    --no-config             Do not load defconfig or apply kconfig
    --no-container-update   Do not update the container image
                            Suppress --local-container
    --dirty                 Build without modifying the source tree.
                            Equals --no-prepare-source --no-config --no-container-update
    --no-build              Prepare the source tree but do not build.
                            Inverse of --dirty
    -p                      Pause after applying patches from each folder
    -n, --native-build      Build without using container
    -l, --local-container   Using locally built container image
    -s, --container-shell   Start a shell inside the container instead of the build
    -d, --debug             Build debug package as well
    --long-version          Add Git commit hash to the end of the version number
    --dtb                   Build dtb only <only valid for linux build>
    -b, --backend [backend] Manually specify container backend. supported values are:
                            docker, podman
    --no-submodule-check    Do not check for submodules
    -h, --help              Show this help message

Alternative commands
    json <catagory>         Print supported options in json format
                            Available catagories: $(get_supported_infos)
    export <profile>        Export profile
    import <profile>        Import profile
    install <disk> [file]   Install built artifact to specified disk
                            Root partition will be determined based on the layout
                            When file is 
                            Supported file types: deb, dtb, dtbo

Supported Linux profile:
$(printf_array "    %s\n" "$(get_supported_edition linux)")

Supported U-Boot profile:
$(printf_array "    %s\n" "$(get_supported_edition u-boot)")
EOF
}

get_supported_product() {
    while (( $# > 0 )) && [[ "$1" == "--" ]]
    do
        shift
    done

    local editions=( "$(get_supported_edition "${1:-}")" )
    if ! in_array "${2:-}" "${editions[@]}" || [[ ! -f "$SCRIPT_DIR/$1/$2/fork.conf" ]]
    then
        error $EXIT_UNKNOWN_OPTION "${2:-}"
    fi

    (
        source "$SCRIPT_DIR/$1/$2/fork.conf"
        echo "${SUPPORTED_BOARDS[@]}"
    )
}

get_supported_product() {
    while (( $# > 0 )) && [[ "$1" == "--" ]]
    do
        shift
    done

    local editions=( "$(get_supported_edition "${1:-}")" )
    if ! in_array "${2:-}" "${editions[@]}"
    then
        error $EXIT_UNKNOWN_OPTION "${2:-}"
    fi

    (
        source "$SCRIPT_DIR/$1/$2/fork.conf"
        echo "${SUPPORTED_BOARDS[@]}"
    )
}

get_supported_edition() {
    while (( $# > 0 )) && [[ "$1" == "--" ]]
    do
        shift
    done

    local components=( "$(get_supported_component)" )
    if ! in_array "${1:-}" "${components[@]}"
    then
        error $EXIT_UNKNOWN_OPTION "${1:-}"
    fi

    local editions=()
    for f in $(ls $SCRIPT_DIR/$1)
    do
        if [[ -f "$SCRIPT_DIR/$1/$f/fork.conf" ]]
        then
            editions+="$f "
        fi
    done
    echo "${editions[@]}"
}

get_supported_component() {
    local components=("linux" "u-boot")
    echo "${components[@]}"
}

get_supported_infos() {
    while (( $# > 0 )) && [[ "$1" == "--" ]]
    do
        shift
    done

    local infos=("edition" "component" "product")
    echo "${infos[@]}"
}

_json() {
    local array=( "$(get_supported_infos)" )
    if ! in_array "$@" "${array[@]}"
    then
        error $EXIT_UNKNOWN_OPTION "${1:-}"
    fi

    local output
    output=( $(get_supported_$@) )
    if (( $? != 0 ))
    then
        return 1
    fi
    printf_array "json" "${output[@]}"
}

usage() {
    less >&2 << EOF
Radxa BSP Build Tool

Usage:

Automatic mode:
    $(basename "$0") [options] <product>

    Automatic mode will search for all supported profiles of a given product,
    and will ask if you want to build the package for the first profiles listed.

    If you want to build an alternative profile, please use the manual mode.

Manual mode:
    $(basename "$0") [options] <linux|u-boot> <profile> [product]

    When building u-boot, you can also provide the 'product' argument,
    which will only build for that specific product, instead of for all products
    supported by the specified profile.

Supported options:
    -h, --help              Show this help message

    Disable safety features:
    --no-submodule-check    Do not check for submodules
    --no-prepare-source     Allow building against locally modified repos
    --no-config             Do not load defconfig or apply kconfig
    --no-container-update   Do not update the container image
                            Suppress --local-container
    --dirty                 Build without modifying the source tree.
                            Equals --no-prepare-source --no-config --no-container-update
    --no-build              Prepare the source tree but do not build.
                            Inverse of --dirty

    Release preparation:
    -r, --revision [num]    Specify custom revision number, default=1
    --long-version          Add Git commit hash to the end of the version number

    Developer options:
    -c, --clean             Run 'make clean' before building
    -C, --distclean         Run 'make distclean' before building
    -p                      Pause after applying patches from each folder
                            Useful when developing for a patch
    -d, --debug             [linux only] Build debug package as well
    --dtb                   [linux only] Build dtb instead of full kernel
                            Useful when developing device trees

    Container behaviors:
    -n, --native-build      Build without using container
    -l, --local-container   Using locally built container image
                            This option will build the container with 'container/Dockerfile'
    -s, --container-shell   Start a shell inside the container instead runnning bsp
                            Intended for examining the build environment
    -b, --backend [backend] Manually specify container backend. supported values are:
                            docker, podman

Alternative sub-commands:
    json <catagory>         Print supported options in json format
                            Available catagories: $(get_supported_info)
    export <profile>        Export profile
    import <profile>        Import profile
    install <target> [file] Install built artifact to the specified target
                            Target can be either block device, or raw disk image
                            Root partition will be determined based on the layout
                            When file is omitted, bsp will drop to a root shell of the target
                            Supported file types: deb, dtb, dtbo

Supported Linux profile:
$(printf_array "    %s\n" "$(get_supported_profile linux)")

Supported U-Boot profile:
$(printf_array "    %s\n" "$(get_supported_profile u-boot)")
EOF
}

get_supported_product() {
    while (( $# > 0 )) && [[ "$1" == "--" ]]
    do
        shift
    done

    local profiles=( "$(get_supported_profile "${1:-}")" )
    if ! in_array "${2:-}" "${profiles[@]}" || [[ ! -f "$SCRIPT_DIR/$1/$2/fork.conf" ]]
    then
        error $EXIT_UNKNOWN_OPTION "${2:-}"
    fi

    (
        source "$SCRIPT_DIR/$1/$2/fork.conf"
        echo "${SUPPORTED_BOARDS[@]}"
    )
}

get_supported_profile() {
    while (( $# > 0 )) && [[ "$1" == "--" ]]
    do
        shift
    done

    local components=( "$(get_supported_component)" )
    if ! in_array "${1:-}" "${components[@]}"
    then
        error $EXIT_UNKNOWN_OPTION "${1:-}"
    fi

    local profiles=()
    for f in $(ls $SCRIPT_DIR/$1)
    do
        if [[ -f "$SCRIPT_DIR/$1/$f/fork.conf" ]]
        then
            profiles+="$f "
        fi
    done
    echo "${profiles[@]}"
}

get_supported_component() {
    local components=("linux" "u-boot")
    echo "${components[@]}"
}

get_supported_info() {
    while (( $# > 0 )) && [[ "$1" == "--" ]]
    do
        shift
    done

    local infos=( "component" "profile" "product")
    echo "${infos[@]}"
}

_json() {
    local array=( "$(get_supported_info)" )
    if ! in_array "${1:-}" "${array[@]}"
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

query_supported_profiles() {
    local component="$1" product="$2"
    local available_profiles=( $(get_supported_profile "$component") )
    local result=() p

    for p in "${available_profiles[@]}"
    do
        if ( source "$SCRIPT_DIR/$component/$p/fork.conf" && in_array "$product" "${SUPPORTED_BOARDS[@]}" )
        then
            result+=("$p")
        fi
    done

    echo "${result[@]}"
}

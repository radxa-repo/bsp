set -euo pipefail
shopt -s nullglob

LC_ALL="C"
LANG="C"
LANGUAGE="C"

CROSS_COMPILE="aarch64-linux-gnu-"

EXIT_SUCCESS=0
EXIT_UNKNOWN_OPTION=1
EXIT_TOO_FEW_ARGUMENTS=2
EXIT_UNSUPPORTED_OPTION=3
EXIT_NO_SUBMODULE=4
EXIT_BAD_BLOCK_DEVICE=5

error() {
    case "$1" in
        $EXIT_SUCCESS)
            ;;
        $EXIT_UNKNOWN_OPTION)
            echo "${FUNCNAME[1]}->${FUNCNAME[0]}: Unknown option: '$2'." >&2
            ;;
        $EXIT_TOO_FEW_ARGUMENTS)
            echo "${FUNCNAME[1]}->${FUNCNAME[0]}: Too few arguments." >&2
            ;;
        $EXIT_UNSUPPORTED_OPTION)
            echo "${FUNCNAME[1]}->${FUNCNAME[0]}: Option '$2' is not supported." >&2
            ;;
        $EXIT_NO_SUBMODULE)
            cat >&2 << EOF
Part of the code in this script are stored in git submodules.
However, it appears that submodules were not initialized in this repo.
Please run "git submodule init && git submodule update" to fix this issue.
EOF
            ;;
        $EXIT_BAD_BLOCK_DEVICE)
            echo "${FUNCNAME[1]}->${FUNCNAME[0]}: '$2' is not a block device." >&2
            ;;
        *)
            echo "${FUNCNAME[1]}->${FUNCNAME[0]}: Unknown exit code." >&2
            ;;
    esac
    
    exit "$1"
}

printf_array() {
    local format="$1"
    shift
    local array=("$@")

    if [[ $format == "json" ]]
    then
        jq --compact-output --null-input '$ARGS.positional' --args -- "${array[@]}"
    else
        for i in ${array[@]}
        do
            printf "$format" "$i"
        done
    fi
}

in_array() {
    local item="$1"
    shift
    local array=("$@")
    if [[ " ${array[*]} " =~ " $item " ]]
    then
        true
    else
        false
    fi
}

git_repo_config() {
    if [[ -z "$(git config --get user.name)" ]]
    then
        git config user.name "bsp"
    fi
    if [[ -z "$(git config --get user.email)" ]]
    then
        git config user.email "bsp@radxa.com"
    fi
}

git_source() {
    local git_url="$1" git_rev="$2"
    __CUSTOM_SOURCE_FOLDER="${3:-$(basename $git_url)}"
    __CUSTOM_SOURCE_FOLDER="${__CUSTOM_SOURCE_FOLDER%.*}"

    mkdir -p "$SCRIPT_DIR/.src/$__CUSTOM_SOURCE_FOLDER"
    pushd "$SCRIPT_DIR/.src/$__CUSTOM_SOURCE_FOLDER"
        git init
        git_repo_config
        git am --abort &>/dev/null || true

        local origin=$(sha1sum <(echo "$git_url") | cut -d' ' -f1)
        git remote add $origin $git_url 2>/dev/null && true

        if (( ${#git_rev} == 40))
        then
            if [[ "$(git rev-parse FETCH_HEAD)" != "$git_rev" ]]
            then
                git fetch --depth 1 $origin $git_rev
            fi
            git reset --hard FETCH_HEAD
            git clean -ffd
            git switch --detach $git_rev
            git tag -f tag_$git_rev
        else
            git fetch --depth 1 $origin tag $git_rev
            git reset --hard FETCH_HEAD
            git clean -ffd
            git switch --detach tags/$git_rev
        fi
    popd
}

git_am() {
    local patch="$(realpath "$1")"
    pushd "$SCRIPT_DIR/.src/$__CUSTOM_SOURCE_FOLDER"
    git am --reject --whitespace=fix "$patch"
    popd
}

source_cp() {
    local file="$(realpath "$1")"
    cp "$file" "$SCRIPT_DIR/.src/$__CUSTOM_SOURCE_FOLDER/$2"
}

prepare_source() {
    local target="$1"
    TARGET_DIR="$SCRIPT_DIR/.src/$target"
    local fork_dir="$SCRIPT_DIR/$target/$FORK"

    mkdir -p "$TARGET_DIR"

    if $LONG_VERSION
    then
        pushd "$SCRIPT_DIR"
        BSP_GITREV="$(git rev-parse --short HEAD^{commit})"
        if ! git diff --quiet
        then
            BSP_GITREV="$BSP_GITREV.dirty"
        fi
        popd
    fi

    pushd "$TARGET_DIR"

        if $NO_PREPARE_SOURCE
        then
            if $LONG_VERSION
            then
                SOURCE_GITREV="$(git rev-parse --short HEAD^{commit}).dirty"
            fi
            popd
            return
        fi

        git init
        git_repo_config
        git am --abort &>/dev/null || true

        local origin=$(sha1sum <(echo "$BSP_GIT") | cut -d' ' -f1)
        git remote add $origin $BSP_GIT 2>/dev/null && true

        if [[ -n $BSP_COMMIT ]]
        then
            if [[ "$(git rev-parse HEAD)" != "$BSP_COMMIT" ]]
            then
                git fetch --depth 1 $origin $BSP_COMMIT
                git reset --hard FETCH_HEAD
                git clean -ffd
                git switch --detach $BSP_COMMIT
                git tag -f tag_$BSP_COMMIT
            fi
        elif [[ -n $BSP_TAG ]]
        then
            git fetch --depth 1 $origin tag $BSP_TAG
            git reset --hard FETCH_HEAD
            git clean -ffd
            git switch --detach tags/$BSP_TAG
        elif [[ -n $BSP_BRANCH ]]
        then
            git fetch --depth 1 $origin $BSP_BRANCH
            git reset --hard FETCH_HEAD
            git clean -ffd
            git switch --detach $origin/$BSP_BRANCH
        fi

        if $LONG_VERSION
        then
            SOURCE_GITREV="$(git rev-parse --short FETCH_HEAD^{commit})"
        fi

        for d in $(find -L $fork_dir -type d | sort -r)
        do
            for f in $d/*.sh
            do
                if [[ $(type -t custom_source_action) == function ]]
                then
                    unset -f custom_source_action
                fi

                source $f

                if [[ $(type -t custom_source_action) == function ]]
                then
                    echo "Running custom_source_action from $f"
                    
                    pushd "$(dirname "$f")"
                    custom_source_action "$SCRIPT_DIR" "$TARGET_DIR"
                    popd
                fi
            done
        done

        for d in $(find -L $fork_dir -type d | sort)
        do
            local patches=()

            if [[ -f $d/PKGBUILD ]]
            then
                echo "Found PKGBUILD"
                local source
                source $d/PKGBUILD
                if (( ${#source[@]} ))
                then
                    for p in "${source[@]}"
                    do
                        if [[ "$p" == *.patch ]]
                        then
                            patches+=("$d/$p")
                        fi
                    done
                fi
            else
                patches=( $d/*.patch )
            fi

            if (( ${#patches[@]} ))
            then
                if [[ -f $d/PKGBUILD ]]
                then
                    for p in "${patches[@]}"
                    do
                        # Manjaro uses patch for fuzzy matching
                        patch -N -p1 < "$p"
                    done
                    git add .
                    git commit --no-verify -m "bsp patchset $(basename $d)"
                else
                    git am --reject --whitespace=fix "${patches[@]}"
                fi
                echo "Patchset $(basename $d) has been applied."
                if $PATCH_PAUSE
                then
                    read -p "Please press enter to continue processing the next patchset: "
                fi
            fi
        done
        
    popd
}

apply_kconfig() {
    if [[ -e "$1" ]]
    then
        pushd "$TARGET_DIR"
        scripts/kconfig/merge_config.sh -m -r .config "$1"
        popd
    fi
}

get_soc_family() {
    case "$1" in
        rk*)
            echo rockchip
            ;;
        s905y2|a311d)
            echo amlogic
            ;;
        *)
            error $EXIT_UNSUPPORTED_OPTION "$1"
            ;;
    esac
}

load_edition() {
    if ! source "$SCRIPT_DIR/lib/$1.sh" 2>/dev/null
    then
        error $EXIT_UNKNOWN_OPTION "$1"
    fi
    TARGET=$1
    bsp_reset

    if ! source "$SCRIPT_DIR/$TARGET/$2/fork.conf" 2>/dev/null
    then
        error $EXIT_UNKNOWN_OPTION "$2"
    fi
    FORK=$2
}
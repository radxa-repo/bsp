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
    local git_url="$1"
    __CUSTOM_SOURCE_FOLDER="$(basename $git_url)"
    __CUSTOM_SOURCE_FOLDER="${__CUSTOM_SOURCE_FOLDER%.*}"

    mkdir -p "$SCRIPT_DIR/.src/$__CUSTOM_SOURCE_FOLDER"
    pushd "$SCRIPT_DIR/.src/$__CUSTOM_SOURCE_FOLDER"
        git init
        git_repo_config
        git am --abort &>/dev/null || true
        if [[ -n $(git status -s) ]]
        then
            git reset --hard FETCH_HEAD || true
            git clean -ffd
        fi

        local origin=$(sha1sum <(echo "$git_url") | cut -d' ' -f1)
        git remote add $origin $git_url 2>/dev/null && true

        if (( ${#2} == 40))
        then
            if [[ "$(git rev-parse FETCH_HEAD)" != "$2" ]]
            then
                git fetch --depth 1 $origin $2
                git switch --detach $2
                git tag -f tag_$2
            fi
        else
            git fetch --depth 1 $origin tag $2
            git switch --detach tags/$2
        fi

        git reset --hard FETCH_HEAD
        git clean -ffd
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

    pushd "$SCRIPT_DIR"
    BSP_GITREV="$(git rev-parse --short HEAD^{commit})"
    if ! git diff --quiet
    then
        BSP_GITREV="$BSP_GITREV.dirty"
    fi
    popd

    pushd "$TARGET_DIR"

        if [[ $NO_PREPARE_SOURCE == "yes" ]]
        then
            SOURCE_GITREV="$(git rev-parse --short FETCH_HEAD^{commit}).dirty"
            popd
            return
        fi

        git init
        git_repo_config
        git am --abort &>/dev/null || true
        if [[ -n $(git status -s) ]]
        then
            git reset --hard FETCH_HEAD || true
            git clean -ffd
        fi

        local origin=$(sha1sum <(echo "$BSP_GIT") | cut -d' ' -f1)
        git remote add $origin $BSP_GIT 2>/dev/null && true

        if [[ -n $BSP_COMMIT ]]
        then
            if [[ "$(git rev-parse FETCH_HEAD)" != "$BSP_COMMIT" ]]
            then
                git fetch --depth 1 $origin $BSP_COMMIT
                git switch --detach $BSP_COMMIT
                git tag -f tag_$BSP_COMMIT
            fi
        elif [[ -n $BSP_TAG ]]
        then
            git fetch --depth 1 $origin tag $BSP_TAG
            git switch --detach tags/$BSP_TAG
        elif [[ -n $BSP_BRANCH ]]
        then
            git fetch --depth 1 $origin $BSP_BRANCH
            git switch --detach $origin/$BSP_BRANCH
        fi

        git reset --hard FETCH_HEAD
        git clean -ffd
        SOURCE_GITREV="$(git rev-parse --short FETCH_HEAD^{commit})"

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
            local patches=( $d/*.patch )
            if (( ${#patches[@]} ))
            then
                git am --reject --whitespace=fix "${patches[@]}"
                echo "Patchset $(basename $d) has been applied."
                if [[ "$PATCH_PAUSE" == "yes" ]]
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
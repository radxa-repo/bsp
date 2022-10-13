set -e
set -o pipefail

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

    if ! [[ -e "$SCRIPT_DIR/.src/$__CUSTOM_SOURCE_FOLDER" ]]
    then
        local git_branch="$2"
        if [[ -n $git_branch ]]
        then
            git_branch="--branch $git_branch"
        fi

        git clone --depth 1 $git_branch "$git_url" "$SCRIPT_DIR/.src/$__CUSTOM_SOURCE_FOLDER"
        pushd "$SCRIPT_DIR/.src/$__CUSTOM_SOURCE_FOLDER"
        git_repo_config
        popd
    else
        unset __CUSTOM_SOURCE_FOLDER
    fi
}

git_am() {
    if [[ -n "$__CUSTOM_SOURCE_FOLDER" ]]
    then
        local patch="$(realpath "$1")"
        pushd "$SCRIPT_DIR/.src/$__CUSTOM_SOURCE_FOLDER"
        git am "$patch"
        popd
    fi
}

source_cp() {
    if [[ -n "$__CUSTOM_SOURCE_FOLDER" ]]
    then
        local file="$(realpath "$1")"
        cp "$file" "$SCRIPT_DIR/.src/$__CUSTOM_SOURCE_FOLDER/$2"
    fi
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
        git am --abort || true
        if [[ -n $(git status -s) ]]
        then
            git reset --hard FETCH_HEAD
            git clean -ffd
        fi

        local origin=$(sha1sum <(echo "$BSP_GIT") | cut -d' ' -f1)
        git remote add $origin $BSP_GIT 2>/dev/null && true

        if [[ -n $BSP_COMMIT ]]
        then
            git fetch --depth 1 $origin $BSP_COMMIT
            git switch --detach $BSP_COMMIT
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
            shopt -s nullglob
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
            shopt -u nullglob
        done

        for d in $(find -L $fork_dir -type d | sort)
        do
            if ls $d/*.patch &>/dev/null
            then
                git am --reject --whitespace=fix $(ls $d/*.patch)
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
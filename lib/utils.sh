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

prepare_source() {
    local target="$1"
    TARGET_DIR="$SCRIPT_DIR/.src/$target"
    local fork_dir="$SCRIPT_DIR/$target/$FORK"

    mkdir -p "$TARGET_DIR"

    if [[ $NO_PREPARE_SOURCE == "yes" ]]
    then
        return
    fi

    pushd "$TARGET_DIR"

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
            git checkout $BSP_COMMIT
            git update-ref refs/tags/$BSP_COMMIT $BSP_COMMIT
        elif [[ -n $BSP_BRANCH ]]
        then
            # Tag is more precise than branch and should be preferred.
            # However, since we are defaulting with upstream Linux,
            # we will always have non empty $BSP_TAG.
            # As such check $BSP_BRANCH first.
            git fetch --depth 1 $origin $BSP_BRANCH
            git checkout $BSP_BRANCH
        elif [[ -n $BSP_TAG ]]
        then
            git fetch --depth 1 $origin tag $BSP_TAG
            git checkout tags/$BSP_TAG
        fi

        git reset --hard FETCH_HEAD
        git clean -ffd

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

kconfig() {
    local mode="config"
    if [[ $1 == "-v" ]]
    then
        mode="verify"
        shift
    fi
    local file="$1"

    while IFS="" read -r k || [ -n "$k" ]
    do
        local config=
        local option=
        local switch=
        if grep -q "^# CONFIG_.* is not set$" <<< $k
        then
            config=$(cut -d ' ' -f 2 <<< $k)
            switch="--undefine"
        elif grep -q "^CONFIG_.*=[ynm]$" <<< $k
        then
            config=$(cut -d '=' -f 1 <<< $k)
            case "$(cut -d'=' -f 2 <<< $k)" in
                y)
                    switch="--enable"
                    ;;
                n)
                    switch="--disable"
                    ;;
                m)
                    switch="--module"
                    ;;
            esac
        elif grep -q "^CONFIG_.*=\".*\"$" <<< $k
        then
            IFS='=' read -r config option <<< $k
            switch="--set-val"
        elif grep -q "^CONFIG_.*=.*$" <<< $k
        then
            IFS='=' read -r config option <<< $k
            switch="--set-val"
        elif grep -q "^#" <<< $k
        then
            continue
        elif [[ -z "$k" ]]
        then
            continue
        else
            error $EXIT_UNKNOWN_OPTION "$k"
        fi
        case $mode in
            config)
                "$SCRIPT_DIR/common/config" --file "$TARGET_DIR/.config" $switch $config "$option"
                ;;
            verify)
                if ! grep -m 1 -q "$k" "$TARGET_DIR/.config"
                then
                    if ! grep -q "^# CONFIG_.* is not set$" <<< $k || grep -m 1 -q "$(cut -d ' ' -f 2 <<< $k)[=\s]" "$TARGET_DIR/.config"
                    then
                        echo "kconfig: Mismatch: $k" >&2
                    fi
                fi
                ;;
        esac
    done < "$file"
}

apply_kconfig() {
    if [[ -e "$1" ]]
    then
        tee -a "$SCRIPT_DIR/.src/build.log" <<< "Apply kconfig from $1"
        kconfig "$1"
        kconfig -v "$1" | tee -a "$SCRIPT_DIR/.src/build.log"
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
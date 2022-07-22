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
            echo "Unknown option: '$2'." >&2
            ;;
        $EXIT_TOO_FEW_ARGUMENTS)
            echo "Too few arguments." >&2
            ;;
        $EXIT_UNSUPPORTED_OPTION)
            echo "Option '$2' is not supported." >&2
            ;;
        *)
            echo "Unknown exit code." >&2
            ;;
    esac
    
    exit "$1"
}

printf_array() {
    local FORMAT="$1"
    shift
    local ARRAY=("$@")

    if [[ $FORMAT == "json" ]]
    then
        jq --compact-output --null-input '$ARGS.positional' --args -- "${ARRAY[@]}"
    else
        for i in ${ARRAY[@]}
        do
            printf "$FORMAT" "$i"
        done
    fi
}

in_array() {
    local ITEM="$1"
    shift
    local ARRAY=("$@")
    if [[ " ${ARRAY[*]} " =~ " $ITEM " ]]
    then
        true
    else
        false
    fi
}

git_source() {
    local GIT_URL="$1"
    local GIT_BRANCH="$2"
    local FOLDER="$(basename $GIT_URL)"
    FOLDER="${FOLDER%.*}"

    if [[ -n $GIT_BRANCH ]]
    then
        GIT_BRANCH="--branch $GIT_BRANCH"
    fi

    if ! [[ -e "$SRC_DIR/$FOLDER" ]]
    then
        git clone --depth 1 $GIT_BRANCH "$GIT_URL" "$SRC_DIR/$FOLDER"
    fi
}

prepare_source() {
    local SRC_DIR="$SCRIPT_DIR/.src"
    local LINUX_DIR="$SRC_DIR/linux"
    local FORK_DIR="$SCRIPT_DIR/forks/$FORK"

    mkdir -p "$SRC_DIR"
    mkdir -p "$LINUX_DIR"

    pushd "$LINUX_DIR"

        git init
        [[ -z $(git config --get user.name) ]] && git config user.name "bsp"
        [[ -z $(git config --get user.email) ]] && git config user.email "bsp@radxa.com"
        git am --abort && true
        [[ -n $(git status -s) ]] && git reset --hard HEAD

        local ORIGIN=$(sha1sum <(echo "$LINUX_GIT") | cut -d' ' -f1)
        git remote add $ORIGIN $LINUX_GIT 2>/dev/null && true

        if [[ -n $LINUX_COMMIT ]]
        then
            git fetch --depth 1 $ORIGIN $LINUX_COMMIT
            git checkout $LINUX_COMMIT
            git update-ref refs/tags/$LINUX_COMMIT $LINUX_COMMIT
        elif [[ -n $LINUX_BRANCH ]]
        then
            # Tag is more precise than branch and should be preferred.
            # However, since we are defaulting with upstream Linux,
            # we will always have non empty $LINUX_TAG.
            # As such check $LINUX_BRANCH first.
            git fetch --depth 1 $ORIGIN $LINUX_BRANCH
            git checkout $LINUX_BRANCH
        elif [[ -n $LINUX_TAG ]]
        then
            git fetch --depth 1 $ORIGIN tag $LINUX_TAG
            git checkout tags/$LINUX_TAG
        fi

        git reset --hard FETCH_HEAD
        git clean -ffd

        for d in $(find -L $FORK_DIR -type d | sort -r)
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
                    custom_source_action "$SCRIPT_DIR" "$UBOOT_DIR"
                fi
            done
            shopt -u nullglob
        done

        for d in $(find -L $FORK_DIR -type d | sort)
        do
            if ls $d/*.patch &>/dev/null
            then
                git am --reject --whitespace=fix $(ls $d/*.patch)
            fi
        done
        
    popd
}

kconfig() {
    local MODE="config"
    if [[ $1 == "-v" ]]
    then
        MODE="verify"
        shift
    fi
    local FILE="$1"

    while IFS="" read -r k || [ -n "$k" ]
    do
        local CONFIG=
        local OPTION=
        local SWITCH=
        if grep -q "^# CONFIG_.* is not set$" <<< $k
        then
            CONFIG=$(cut -d ' ' -f 2 <<< $k)
            SWITCH="--undefine"
        elif grep -q "^CONFIG_.*=[ynm]$" <<< $k
        then
            CONFIG=$(echo $k | cut -d '=' -f 1)
            case "$(echo $k | cut -d'=' -f 2)" in
                y)
                    SWITCH="--enable"
                    ;;
                n)
                    SWITCH="--disable"
                    ;;
                m)
                    SWITCH="--module"
                    ;;
            esac
        elif grep -q "^CONFIG_.*=\".*\"$" <<< $k
        then
            IFS='=' read -r CONFIG OPTION <<< $k
            SWITCH="--set-val"
        elif grep -q "^CONFIG_.*=.*$" <<< $k
        then
            IFS='=' read -r CONFIG OPTION <<< $k
            SWITCH="--set-val"
        elif grep -q "^#" <<< $k
        then
            continue
        elif [[ -z "$k" ]]
        then
            continue
        else
            error $EXIT_UNKNOWN_OPTION "$k"
        fi
        case $MODE in
            config)
                "$SCRIPT_DIR/.src/linux/scripts/config" --file "$SCRIPT_DIR/.src/linux/.config" $SWITCH $CONFIG "$OPTION"
                ;;
            verify)
                if ! grep -q "$k" "$SCRIPT_DIR/.src/linux/.config"
                then
                    echo "kconfig: Mismatch: $k" >&2
                fi
                ;;
        esac
    done < "$FILE"
}

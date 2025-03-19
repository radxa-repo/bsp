container_exec() {
    if [[ "$(basename "$CONTAINER_BACKEND")" == "docker" ]] && "$CONTAINER_BACKEND" --help | grep -q podman
    then
        echo "'$CONTAINER_BACKEND' backend is selected, but the functionality is actually provided by 'podman' backend. Updating accordingly..."
        CONTAINER_BACKEND="$(command -v podman)"
    fi

    local CONTAINER_IMAGE="$($CONTAINER_BACKEND image ls "-qf=reference=${CONTAINER_REGISTRY}bsp:main")"
    local CONTAINER_EXIT_CODE=0

    if ! $NO_CONTAINER_UPDATE
    then
        if [[ -z $CONTAINER_REGISTRY ]]
        then
            $CONTAINER_BACKEND image rm "${CONTAINER_REGISTRY}bsp:main" &>/dev/null || true
            $CONTAINER_BACKEND build -t "${CONTAINER_REGISTRY}bsp:main" "$SCRIPT_DIR/container"
        else
            $CONTAINER_BACKEND pull "${CONTAINER_REGISTRY}bsp:main"
        fi
    fi

    if [[ $CONTAINER_IMAGE != "$($CONTAINER_BACKEND image ls "-qf=reference=${CONTAINER_REGISTRY}bsp:main")" ]]
    then
        $CONTAINER_BACKEND container rm bsp &>/dev/null || true
        $CONTAINER_BACKEND image rm "${CONTAINER_REGISTRY}bsp:builder" &>/dev/null || true
    fi

    CONTAINER_BUILDER="$($CONTAINER_BACKEND image ls "-qf=reference=${CONTAINER_REGISTRY}bsp:builder")"
    if [[ -z $CONTAINER_BUILDER ]]
    then
        $CONTAINER_BACKEND tag "${CONTAINER_REGISTRY}bsp:main" "${CONTAINER_REGISTRY}bsp:builder"
    fi

    CONTAINER_OPTIONS=( "--name" "bsp" )
    CONTAINER_OPTIONS+=( "--workdir" "$PWD" )
    CONTAINER_OPTIONS+=( "--mount" "type=bind,source=$PWD,destination=$PWD" )
    # Check if the kernel path is a soft link
    if [ -L "$SCRIPT_DIR/.src/linux" ]; then
        TARGET_REAL_PATH=$(readlink -f "$SCRIPT_DIR/.src/linux")
        CONTAINER_OPTIONS+=( "--mount" "type=bind,source=$TARGET_REAL_PATH,destination=$TARGET_REAL_PATH")
    fi

    if [[ -t 0 ]]
    then
        CONTAINER_OPTIONS+=( "-it" )
    fi
    if [[ "$PWD" != "$SCRIPT_DIR" ]]
    then
        CONTAINER_OPTIONS+=( "--mount" "type=bind,source=$SCRIPT_DIR,destination=$SCRIPT_DIR" )
    fi
    $CONTAINER_BACKEND container kill bsp &>/dev/null || true
    $CONTAINER_BACKEND container rm bsp &>/dev/null || true
    if [[ "$(basename "$CONTAINER_BACKEND")" == "podman" ]]
    then
        CONTAINER_OPTIONS+=( "--user" "root" )
        if $CONTAINER_SHELL
        then
            if ! $CONTAINER_BACKEND run "${CONTAINER_OPTIONS[@]}" "${CONTAINER_REGISTRY}bsp:builder" bash
            then
                CONTAINER_EXIT_CODE="$($CONTAINER_BACKEND inspect bsp --format='{{.State.ExitCode}}')"
            fi
        else
            if ! $CONTAINER_BACKEND run "${CONTAINER_OPTIONS[@]}" "${CONTAINER_REGISTRY}bsp:builder" bash -c "\"$0\" --native-build ${ARGV[*]}"
            then
                CONTAINER_EXIT_CODE="$($CONTAINER_BACKEND inspect bsp --format='{{.State.ExitCode}}')"
            fi
            $CONTAINER_BACKEND container rm bsp
        fi
    else
        local CONTAINER_SUDO="sed -i -E \"s/^(runner):(x?):([0-9]+):([0-9]+):(.*):(.*):(.*)$/\1:\2:$(id -u):$(id -g):\5:\6:\7/\" /etc/passwd && sudo -u runner"
        if $CONTAINER_SHELL
        then
            if ! $CONTAINER_BACKEND run "${CONTAINER_OPTIONS[@]}" "${CONTAINER_REGISTRY}bsp:builder" bash -c "$CONTAINER_SUDO -i"
            then
                CONTAINER_EXIT_CODE="$($CONTAINER_BACKEND inspect bsp --format='{{.State.ExitCode}}')"
            fi
        else
            if ! $CONTAINER_BACKEND run "${CONTAINER_OPTIONS[@]}" "${CONTAINER_REGISTRY}bsp:builder" bash -c "$CONTAINER_SUDO \"$0\" --native-build ${ARGV[*]}"
            then
                CONTAINER_EXIT_CODE="$($CONTAINER_BACKEND inspect bsp --format='{{.State.ExitCode}}')"
            fi
            $CONTAINER_BACKEND container rm bsp
        fi
    fi
    return $CONTAINER_EXIT_CODE
}

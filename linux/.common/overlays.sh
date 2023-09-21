custom_source_action() {
    git_source https://github.com/radxa/overlays.git 5ea5d8fa83bd1ba4f875f33c95550a3dbaa53e5b
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

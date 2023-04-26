custom_source_action() {
    git_source https://github.com/radxa/overlays.git 867a3e91729fa9f443a4c89b9a90b1455a18e7e4
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
custom_source_action() {
    git_source https://github.com/radxa/overlays.git 242f2c8280fc032f294512a97bace65317adf34c
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
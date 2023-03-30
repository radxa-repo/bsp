custom_source_action() {
    git_source https://github.com/radxa/overlays.git 9ab10fc85b37199e37cd4ebccc78c8d7b65a693e
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
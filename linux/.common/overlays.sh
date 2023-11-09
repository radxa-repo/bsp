custom_source_action() {
    git_source https://github.com/radxa/overlays.git 2ac9a75d098800d3038737ed48387d2a8db94355
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

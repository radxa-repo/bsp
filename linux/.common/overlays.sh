custom_source_action() {
    git_source https://github.com/radxa-pkg/radxa-overlays.git 04de4cab2c5eba53cb2caff940b78822dac50ab5
    cp -r $SCRIPT_DIR/.src/radxa-overlays/arch $TARGET_DIR
}

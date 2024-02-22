custom_source_action() {
    git_source https://github.com/radxa/overlays.git 99dcfbce60a09f54ad8fe99d24720800ffa8a89e
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

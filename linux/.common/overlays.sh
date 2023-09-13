custom_source_action() {
    git_source https://github.com/radxa/overlays.git 0dcc88e63b008bf7d29646e56ec96c58bbe96414
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

custom_source_action() {
    git_source https://github.com/radxa/overlays.git 1d863a6190fa4127fd886984b487525f13c98e42
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

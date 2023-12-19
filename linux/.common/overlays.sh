custom_source_action() {
    git_source https://github.com/radxa/overlays.git 8850e7abbf718b2bc0471726ac5b03b11bb98fbb
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

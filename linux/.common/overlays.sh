custom_source_action() {
    git_source https://github.com/radxa/overlays.git 703d3eb12118f8360b3b66574a0267bbe1c6d8ff
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
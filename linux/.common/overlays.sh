custom_source_action() {
    git_source https://github.com/radxa/overlays.git 6bccf289e31a9d767ef21f210ee0d0ea3cce764c
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
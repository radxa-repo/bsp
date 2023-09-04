custom_source_action() {
    git_source https://github.com/radxa/overlays.git 7eb7f4bdc392241bd958db4aac647dd742bf19ef
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

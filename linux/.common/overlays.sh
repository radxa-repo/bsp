custom_source_action() {
    git_source https://github.com/radxa/overlays.git af2842c0d740ebc4ae8c3e358e96cb8c9676b558
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

custom_source_action() {
    git_source https://github.com/radxa/overlays.git 2d4109f9066251df2cf09ab2e4a7a104287f820d
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

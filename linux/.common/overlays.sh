custom_source_action() {
    git_source https://github.com/radxa/overlays.git 1d380f3489a4839034eea7c775b714737e50b8cb
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

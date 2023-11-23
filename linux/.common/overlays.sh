custom_source_action() {
    git_source https://github.com/radxa/overlays.git 06383f2ffa49e1eb93538bb936580b2150a7ddfe
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

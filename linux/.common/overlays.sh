custom_source_action() {
    git_source https://github.com/radxa/overlays.git 531d034da4bce81f0735463322f9c1719a41dfd8
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

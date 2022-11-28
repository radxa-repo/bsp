custom_source_action() {
    git_source https://github.com/radxa/overlays.git c9c73f94114160693a5d571432630c39c0671742
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
custom_source_action() {
    git_source https://github.com/radxa/overlays.git 90a29d8729b61b7f20015cad4a10e48104d8788b
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
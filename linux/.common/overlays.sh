custom_source_action() {
    git_source https://github.com/radxa/overlays.git 15348e77bddf851cbb2989acb5f231ad4117a96f
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

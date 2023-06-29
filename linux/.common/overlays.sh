custom_source_action() {
    git_source https://github.com/radxa/overlays.git 280849a095f03d0f7ab54a5fea8500a7a7ae6de6
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

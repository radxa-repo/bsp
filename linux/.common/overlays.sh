custom_source_action() {
    git_source https://github.com/radxa/overlays.git bfc6516f480ae8eb1ec516eafe3739cfd974c375
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

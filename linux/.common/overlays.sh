custom_source_action() {
    git_source https://github.com/radxa/overlays.git d132c8473122932be8c7f58b01944e5e3203e902
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

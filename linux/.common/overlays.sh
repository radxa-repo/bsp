custom_source_action() {
    git_source https://github.com/radxa/overlays.git cfa77e28d08ad50ac72ee325d18f04323b1db1d6
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
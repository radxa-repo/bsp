custom_source_action() {
    git_source https://github.com/radxa/overlays.git d0970ace0778e5d69f9e09cc7d9608d2156fda57
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

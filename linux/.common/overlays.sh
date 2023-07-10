custom_source_action() {
    git_source https://github.com/radxa/overlays.git 39aec71d10078c0bb1debe9f805648c62072a221
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

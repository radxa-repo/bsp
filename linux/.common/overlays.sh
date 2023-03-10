custom_source_action() {
    git_source https://github.com/radxa/overlays.git 9c3a476ff3b749f34908a64bc67aa01fcd7d3cd2
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
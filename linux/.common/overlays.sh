custom_source_action() {
    git_source https://github.com/radxa/overlays.git 083726b6521ed22ce41655d44cb5af460e58bc59
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

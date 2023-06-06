custom_source_action() {
    git_source https://github.com/radxa/overlays.git d40019c2165d2cd8d03cf2be5d8713cd118fca9c
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

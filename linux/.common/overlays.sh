custom_source_action() {
    git_source https://github.com/radxa/overlays.git a997ee04caab8b5b1216bd2260e198d2996df89b
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
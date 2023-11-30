custom_source_action() {
    git_source https://github.com/radxa/overlays.git a41a4d7270863e2c70f99cb04f017e0504681134
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

custom_source_action() {
    git_source https://github.com/radxa/overlays.git aee0605442ebe67c2e9fbc58343621f3b1895774
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
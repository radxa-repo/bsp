custom_source_action() {
    git_source https://github.com/radxa/overlays.git a0c162e928c2f02b99caa941eef3ba2e5849c35d
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

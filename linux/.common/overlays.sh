custom_source_action() {
    git_source https://github.com/radxa/overlays.git feaa978f80525e3943184615ec0e1a7128c352b8
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

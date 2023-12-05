custom_source_action() {
    git_source https://github.com/radxa/overlays.git f991888f5566ea167c391547ac526112c6264b1e
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

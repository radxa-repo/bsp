custom_source_action() {
    git_source https://github.com/radxa/overlays.git db606fbdb4ee0c9653bb28d6be7b0b6c2e5e376e
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

custom_source_action() {
    git_source https://github.com/radxa/overlays.git f8099f20b45b7fb8d577a5c94ec4c757a34f05a6
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
custom_source_action() {
    git_source https://github.com/radxa/overlays.git 4ee11f8f1421f90b2e41e5cdc940c5ca47f48ef6
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

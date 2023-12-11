custom_source_action() {
    git_source https://github.com/radxa/overlays.git bc4b448889733a8af4191079e7104774813688dc
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

custom_source_action() {
    git_source https://github.com/radxa/overlays.git 8b72bae4e52720a1bd311f35f724be141616e909
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
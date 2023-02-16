custom_source_action() {
    git_source https://github.com/radxa/overlays.git d247bbde15fb64d58ad822fd9faf1f4d31945465
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
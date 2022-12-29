custom_source_action() {
    git_source https://github.com/radxa/overlays.git af33e90d6deab7c183230e98abf2eab195a79d1d
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
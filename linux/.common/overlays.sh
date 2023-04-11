custom_source_action() {
    git_source https://github.com/radxa/overlays.git 90f3f68eb3584ed508cb01efadd81e3b5a7dee91
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
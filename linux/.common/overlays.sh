custom_source_action() {
    git_source https://github.com/radxa-pkg/radxa-overlays.git e1501186b47154d0fc9dd9881ee97597181f0923
    cp -r $SCRIPT_DIR/.src/radxa-overlays/arch $TARGET_DIR
}

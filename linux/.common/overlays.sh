custom_source_action() {
    git_source https://github.com/radxa-pkg/radxa-overlays.git 165101555f9db6833f1b6e1748dcbf3beaf8085e
    cp -r $SCRIPT_DIR/.src/radxa-overlays/arch $TARGET_DIR
}

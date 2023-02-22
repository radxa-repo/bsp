custom_source_action() {
    git_source https://github.com/radxa/overlays.git 23d0c4ae350f1ab94d72e7fe486f120826504401
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
custom_source_action() {
    git_source https://github.com/radxa/overlays.git 9a56937d22a4e74eb66edfe99e4db86c28e45fa1
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

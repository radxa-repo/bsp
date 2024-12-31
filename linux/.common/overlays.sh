custom_source_action() {
    git_source https://github.com/radxa-pkg/radxa-overlays.git 743daac2a48a66d74bbd2f9a9450907e91c7b6a8
    cp -r $SCRIPT_DIR/.src/radxa-overlays/arch $TARGET_DIR
}

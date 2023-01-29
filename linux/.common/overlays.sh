custom_source_action() {
    git_source https://github.com/radxa/overlays.git 5d8de27b8cc035b0298c9fe7e91f82a8e455e121
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
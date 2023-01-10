custom_source_action() {
    git_source https://github.com/radxa/overlays.git 3ed94d7aef633d852fca4793ea6510762f668835
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
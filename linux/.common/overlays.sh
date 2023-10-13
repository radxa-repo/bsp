custom_source_action() {
    git_source https://github.com/radxa/overlays.git 251341ae0fd18176967206208824cef6cabbf8b1
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

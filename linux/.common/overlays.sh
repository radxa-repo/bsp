custom_source_action() {
    git_source https://github.com/radxa/overlays.git 4940ae33e4def0fb9133faf68adf0c3421b61f06
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
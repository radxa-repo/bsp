custom_source_action() {
    git_source https://github.com/radxa/overlays.git 119f3c26f6ba4f31ba870ca5a6c0e2009e99474b
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

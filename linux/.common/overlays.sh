custom_source_action() {
    git_source https://github.com/radxa/overlays.git 7304b961cb0ce51c18ea0df8b0fb5c21db4d053a
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
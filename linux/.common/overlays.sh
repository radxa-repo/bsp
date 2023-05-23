custom_source_action() {
    git_source https://github.com/radxa/overlays.git 0ab4f0afd79535ae18360d865df300b943e630b9
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

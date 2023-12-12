custom_source_action() {
    git_source https://github.com/radxa/overlays.git ef1ad13c364f856a8c6ba64e29d7bf16f75d6584
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

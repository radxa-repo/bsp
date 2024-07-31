custom_source_action() {
    git_source https://github.com/radxa-pkg/radxa-overlays.git 4d9bb5f32f25fd3125ccdd44dac44a84f1aa7381
    cp -r $SCRIPT_DIR/.src/radxa-overlays/arch $TARGET_DIR
}

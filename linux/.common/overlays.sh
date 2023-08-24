custom_source_action() {
    git_source https://github.com/radxa/overlays.git 10bb8a22501c7f47c5568e958d41ba83ea3e70fe
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

custom_source_action() {
    git_source https://github.com/radxa/overlays.git 5b4216d0f927c16a8a1eae75e50e2cf3ee6a6eba
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
custom_source_action() {
    git_source https://github.com/radxa-pkg/radxa-overlays.git 851cb8309cdd6f24406ea896ad610e8e3d8ca3be
    cp -r $SCRIPT_DIR/.src/radxa-overlays/arch $TARGET_DIR
}

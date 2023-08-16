custom_source_action() {
    git_source https://github.com/radxa/overlays.git 11d5cbf6cebc98b0244de968a828ccd9e73069d5
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

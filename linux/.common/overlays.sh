custom_source_action() {
    git_source https://github.com/radxa/overlays.git 3def01869b4c33843b74ac64c71cf70cb93189e3
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
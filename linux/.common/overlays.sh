custom_source_action() {
    git_source https://github.com/radxa/overlays.git 09ec6d0dea6f245480220d507685d716563ea8d6
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

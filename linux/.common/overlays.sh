custom_source_action() {
    git_source https://github.com/radxa/overlays.git ce2dad94afc1178bb8716042dd9d8b460aa3eb85
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

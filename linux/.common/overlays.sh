custom_source_action() {
    git_source https://github.com/radxa-pkg/radxa-overlays.git 4f8f528b21f86c7dbca8f84b6e6c5e915685cbde
    cp -r $SCRIPT_DIR/.src/radxa-overlays/arch $TARGET_DIR
}

custom_source_action() {
    git_source https://github.com/radxa-pkg/radxa-overlays.git cfc96d08636a7584b463f33155e28cab8188e511
    cp -r $SCRIPT_DIR/.src/radxa-overlays/arch $TARGET_DIR
}

custom_source_action() {
    git_source https://github.com/radxa-pkg/radxa-overlays.git 644f1317171edee1c2d6373b7a51bad3a3f96a83
    cp -r $SCRIPT_DIR/.src/radxa-overlays/arch $TARGET_DIR
}

custom_source_action() {
    git_source https://github.com/radxa/overlays.git 568888a326af14ffea8f5c7cc08e6e80dea9a58d
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
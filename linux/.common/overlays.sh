custom_source_action() {
    git_source https://github.com/radxa/overlays.git 3d84b485826116fde18f047f61c974ce42922767
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
custom_source_action() {
    git_source https://github.com/radxa/overlays.git 6769ddfeb2015e88d99f30604beb2fb45950013f
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

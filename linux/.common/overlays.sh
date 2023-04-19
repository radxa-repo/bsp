custom_source_action() {
    git_source https://github.com/radxa/overlays.git 555c3aadecc469abd52b1edc0d0523b6b3628e1e
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
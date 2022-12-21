custom_source_action() {
    git_source https://github.com/radxa/overlays.git d34e95251b10d6db3c30e7ef609ccc70432a49c8
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
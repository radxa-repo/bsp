custom_source_action() {
    git_source https://github.com/radxa/overlays.git fadb8d52ebac45055e382b179addc744ca902e3c
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

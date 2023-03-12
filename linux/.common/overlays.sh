custom_source_action() {
    git_source https://github.com/radxa/overlays.git 6b533c138d87abdcadcb0147f13bfe5c129b3e2a
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
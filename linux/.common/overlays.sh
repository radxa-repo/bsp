custom_source_action() {
    git_source https://github.com/radxa/overlays.git 33ac37eb2da4ac14527769348d243f63afdc66cd
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
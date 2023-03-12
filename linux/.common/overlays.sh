custom_source_action() {
    git_source https://github.com/radxa/overlays.git 1ad6778a2f8c14a92e6a61157791655dbc5d1727
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
custom_source_action() {
    git_source https://github.com/radxa/overlays.git 29d53d7597de2335417a741acb016b2764dd33ba
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

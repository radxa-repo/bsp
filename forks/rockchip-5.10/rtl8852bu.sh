custom_source_action() {
    git_source https://github.com/radxa/rtl8852bu.git
    cp -r $SRC_DIR/rtl8852bu $LINUX_DIR/drivers/net/wireless
}
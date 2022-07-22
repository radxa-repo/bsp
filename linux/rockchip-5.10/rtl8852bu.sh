custom_source_action() {
    git_source https://github.com/radxa/rtl8852bu.git
    git_source https://github.com/radxa/rtkbt.git
    cp -r $SRC_DIR/rtl8852bu $TARGET_DIR/drivers/net/wireless
    cp -r $SRC_DIR/rtkbt $TARGET_DIR/drivers/bluetooth
}
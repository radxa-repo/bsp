custom_source_action() {
    git_source "https://github.com/rockchip-linux/rkbin.git" b0c100f1a260d807df450019774993c761beb79d
    git_am "./0002-Disable-bl32-for-rk3399.rkbin"
}
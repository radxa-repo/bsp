custom_source_action() {
    case $BSP_SOC in
        rk3308|rk3328|rk3399)
            git_source "https://github.com/radxa/rkbin.git" 9840e87723eef7c41235b89af8c049c1bcd3d133
            git_am "./0001-Update-rkbin.rkbin"
            git_am "./0002-Disable-bl32-for-rk3399.rkbin"
            git_am "./0003-Fix-side-effect-of-broken-rkbin-history.rkbin"
            source_cp "./boot_merger" "tools/"
            ;;
        *)
            git_source "https://github.com/rockchip-linux/rkbin.git" b0c100f1a260d807df450019774993c761beb79d
            ;;
    esac
}
custom_source_action() {
    case $BSP_SOC in
        rk3308)
            git_source "https://github.com/RadxaYuntian/rkbin.git" fba57c2f676fcea54ec8317c90d04ee9ff0aff66
            ;;
        rk3399)
            git_source "https://github.com/radxa/rkbin.git" cd2b28dc2c83dccdd99266bb2c43ea525bbf6c18
            git_am "./0001-Update-rkbin.rkbin"
            git_am "./0002-Disable-bl32-for-rk3399.rkbin"
            git_am "./0003-Fix-side-effect-of-broken-rkbin-history.rkbin"
            ;;
        *)
            git_source "https://github.com/radxa/rkbin.git" 789dd24dacd7b6b5f57199437b6a6d31953311a3
            ;;
    esac
}

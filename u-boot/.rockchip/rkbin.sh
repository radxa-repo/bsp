custom_source_action() {
    case $BSP_SOC in
        rk3308)
            git_source "https://github.com/radxa/rkbin.git" 9e048f5694b019794dba077ca4871a009fa9be0f
            ;;
        *)
            git_source "https://github.com/radxa/rkbin.git" 08af6e19f7f7bab1a28d3db7d5b31e15c7d88bba
            ;;
    esac
}

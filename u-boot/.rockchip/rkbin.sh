custom_source_action() {
    case $BSP_SOC in
        rk3308)
            git_source "https://github.com/radxa/rkbin.git" 9e048f5694b019794dba077ca4871a009fa9be0f
            ;;
        *)
            git_source "https://github.com/radxa/rkbin.git" 2b54df9d062ef91a9fffbc85472b070c9220c4cf
            ;;
    esac
}

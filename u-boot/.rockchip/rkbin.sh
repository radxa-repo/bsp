custom_source_action() {
    case $BSP_SOC in
        rk3308)
            git_source "https://github.com/radxa/rkbin.git" 9e048f5694b019794dba077ca4871a009fa9be0f
            ;;
        *)
            git_source "https://github.com/radxa/rkbin.git" 69de99907a4b51e4012c704502d234ea3c0f0423
            ;;
    esac
}

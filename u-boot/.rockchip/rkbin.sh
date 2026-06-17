custom_source_action() {
    case $BSP_SOC in
        rk3308)
            git_source "https://github.com/radxa/rkbin.git" 9e048f5694b019794dba077ca4871a009fa9be0f
            ;;
        *)
            git_source "https://github.com/radxa/rkbin.git" 02931bbd3f9756cbad556d73f6447b9a5b3fc240
            ;;
    esac
}

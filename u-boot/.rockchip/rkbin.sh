custom_source_action() {
    case $BSP_SOC in
        rk3308)
            git_source "https://github.com/RadxaYuntian/rkbin.git" fba57c2f676fcea54ec8317c90d04ee9ff0aff66
            ;;
        *)
            git_source "https://github.com/radxa/rkbin.git" b0e55f98f0a8a5993cab9d81a40cf3c4255a34fb
            ;;
    esac
}

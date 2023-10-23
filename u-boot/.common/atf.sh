custom_source_action() {
    git_source "https://github.com/ARM-software/arm-trusted-firmware.git" "v2.9.0"
    git_patch "./enable-logging.atf"
    git_patch "./rk3328-efuse-init.atf"
}
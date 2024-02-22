custom_source_action() {
    git_source "https://github.com/ARM-software/arm-trusted-firmware.git" "lts-v2.10.2"
    git_patch "./enable-logging.atf"
    git_patch "./rk3328-efuse-init.atf"
}
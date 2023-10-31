custom_source_action() {
    # mtk-v2.6
    git_source "https://gitlab.com/mediatek/aiot/bsp/trusted-firmware-a.git" "11a3e271252e3f7583046615c1e8b3b33533d636" "mtk-atf"
    # mtk-v3.19
    git_source "https://gitlab.com/mediatek/aiot/bsp/optee-os.git" "8b7fb28b69f45208500847af1975da26a225c02a" "mtk-optee"
    git_source "https://gitlab.com/mediatek/aiot/rity/lk-prebuilt.git" "c76361b2704e12d41fb9082aae03f9b68aa9e9a4"
    git_source "https://gitlab.com/mediatek/aiot/rity/libdram-prebuilt.git" "df294e73ab8064cbb8da3f3987f4d8829dd9fa73"
    git_source "https://gitlab.com/mediatek/aiot/bsp/libbase-prebuilt.git" "6a47bf6b96e1f51776ea397703d381e34a1596c4"
}
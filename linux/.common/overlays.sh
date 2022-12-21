custom_source_action() {
    git_source https://github.com/radxa/overlays.git 6cac85db79ae013b0687ac8cd45e82bb8c616047
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
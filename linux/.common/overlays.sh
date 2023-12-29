custom_source_action() {
    git_source https://github.com/radxa/overlays.git 05867d04c3175f7c7751b9ce71b9616dbddf1871
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

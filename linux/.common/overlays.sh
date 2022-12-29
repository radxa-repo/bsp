custom_source_action() {
    git_source https://github.com/radxa/overlays.git 467e9eeacc179247f5acb085cefc8d5236354615
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
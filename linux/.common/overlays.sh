custom_source_action() {
    git_source https://github.com/radxa/overlays.git df81b261a59811266994dd62c166ada0bd9ef08d
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}
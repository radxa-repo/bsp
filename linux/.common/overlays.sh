custom_source_action() {
    git_source https://github.com/radxa/overlays.git bbd7420526accd3e400da48878e1dbe9d510c092
    cp -r $SCRIPT_DIR/.src/overlays/arch $TARGET_DIR
}

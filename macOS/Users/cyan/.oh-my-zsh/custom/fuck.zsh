function fuck() {
    if test "$@"; then
        sudo $@
    else
        sudo $(fc -ln -1)
    fi
}

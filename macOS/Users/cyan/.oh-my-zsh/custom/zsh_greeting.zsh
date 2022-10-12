function zsh_greeting() {
    clear
    pfetch
    echo "It's currently $(~/bin/weather)."
    fortune -n 50 -s
    echo
}

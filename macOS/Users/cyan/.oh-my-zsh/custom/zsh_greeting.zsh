# This script waits for 5 seconds, allowing system's boot messages to display, before showing a greeting and a fortune quote.

function zsh_greeting() {
    sleep 5
    clear
    pfetch
    echo "It's currently $(~/bin/weather)."
    fortune -n 50 -s
    echo
}

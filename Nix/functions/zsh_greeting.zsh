# This script displays a system greeting with system info.

function zsh_greeting() {
    clear

    # Display system information if available
    if command -v pfetch >/dev/null 2>&1; then
        pfetch
    fi

    # Display outdated packages from Homebrew
    if ping -c 1 brew.sh >/dev/null 2>&1; then
        outdated_count=$(HOMEBREW_NO_AUTO_UPDATE=1 brew outdated 2>/dev/null | wc -l | xargs)
        echo "You have ${outdated_count} outdated package(s)."
    fi

}

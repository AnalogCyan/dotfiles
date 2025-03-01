# This script displays a system greeting with various components like system info, weather, and fortune quotes.
# Configuration variables
GREETING_SLEEP_DURATION=${GREETING_SLEEP_DURATION:-5} # Configurable sleep duration, default 5 seconds
GREETING_COLOR=${GREETING_COLOR:-"\033[1;34m"}        # Default to blue
RESET_COLOR="\033[0m"

# Helper function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Helper function for colored output
print_colored() {
    echo -e "${GREETING_COLOR}$1${RESET_COLOR}"
}

function zsh_greeting() {
    # Wait for boot messages if needed
    if [[ $GREETING_SLEEP_DURATION -gt 0 ]]; then
        sleep $GREETING_SLEEP_DURATION
    fi

    clear

    # System information
    if command_exists pfetch; then
        pfetch
    fi

    # Weather information - Check various possible paths for weather script
    if command_exists weather; then
        print_colored "Current weather: $(weather)"
    elif [[ -x "$HOME/bin/weather" ]]; then
        print_colored "Current weather: $($HOME/bin/weather)"
    elif [[ -x "${XDG_CONFIG_HOME:-$HOME/.config}/weather/weather" ]]; then
        print_colored "Current weather: $(${XDG_CONFIG_HOME:-$HOME/.config}/weather/weather)"
    fi

    # Fortune message
    if command_exists fortune; then
        print_colored "Today's fortune:"
        fortune -n 50 -s
    fi

    echo
}

# Enhanced directory listing with logo-ls or fallbacks
# Usage: ls [options] [path]

function ls() {
  # Set color variables
  local reset="\033[0m"
  local red="\033[0;31m"
  local yellow="\033[0;33m"

  if command -v logo-ls >/dev/null 2>&1; then
    logo-ls "$@"
  elif command -v exa >/dev/null 2>&1; then
    echo -e "${yellow}Using exa instead of logo-ls${reset}"
    exa --icons "$@"
  else
    echo -e "${red}logo-ls not found, using system ls${reset}"
    if [[ "$(uname)" == "Darwin" ]]; then
      command ls -G "$@"
    else
      command ls "$@"
    fi
  fi
}

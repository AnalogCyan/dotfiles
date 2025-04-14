function ls() {
  # Define color variables for messages
  local reset="\033[0m"
  local red="\033[0;31m"
  local yellow="\033[0;33m"

  # Use logo-ls if available
  if command -v logo-ls >/dev/null 2>&1; then
    logo-ls "$@"
    return $?
  fi

  # Fallback to exa if logo-ls is not available
  if command -v exa >/dev/null 2>&1; then
    exa --icons "$@"
    return $?
  fi

  # If neither logo-ls nor exa are found, fall back to the system ls.
  echo -e "${red}logo-ls not found, using system ls${reset}"
  if [[ "$(uname)" == "Darwin" ]]; then
    command ls -G "$@"
  else
    command ls "$@"
  fi
}

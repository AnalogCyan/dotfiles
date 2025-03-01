# Enhanced directory listing with colorization and fallbacks
# Usage: lsd [options] [path]
# Tries different ls-like commands in order of richness and pipes through lolcat

function lsd() {
  # Check if lolcat is available
  if ! command -v lolcat &>/dev/null; then
    echo "Error: lolcat is required but not installed" >&2
    return 1
  fi

  # Store arguments for later use
  local args=("$@")
  local cmd_output=""

  # Try commands in order of feature richness
  if command -v logo-ls &>/dev/null; then
    cmd_output=$(logo-ls --color=always "${args[@]}" 2>/dev/null)
  elif command -v exa &>/dev/null; then
    cmd_output=$(exa --color=always --icons "${args[@]}" 2>/dev/null)
  elif command -v lsd &>/dev/null; then
    cmd_output=$(lsd --color=always "${args[@]}" 2>/dev/null)
  else
    # Fallback to system ls with appropriate color flag
    if [[ "$(uname)" == "Darwin" ]]; then
      cmd_output=$(command ls -G "${args[@]}" 2>/dev/null)
    else
      cmd_output=$(command ls --color=always "${args[@]}" 2>/dev/null)
    fi
  fi

  # If we have output, pipe it through lolcat
  if [[ -n "$cmd_output" ]]; then
    echo "$cmd_output" | lolcat -t
  else
    echo "Error: Failed to list directory contents" >&2
    return 1
  fi
}

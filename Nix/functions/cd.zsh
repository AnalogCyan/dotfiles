# Enhanced zoxide integration for directory navigation
# Usage: cd [path]

function cd() {
  # If no arguments provided, go to home directory using zoxide
  if [ $# -eq 0 ]; then
    z ~
    return $?
  fi

  # Try to navigate using zoxide
  if ! z "$@"; then
    # If zoxide fails, try regular cd as fallback
    if ! builtin cd "$@"; then
      echo "Error: Directory '$@' not found" >&2
      return 1
    fi
  fi
}

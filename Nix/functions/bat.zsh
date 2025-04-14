function bat() {
  # No arguments: if no file provided, read from standard input using batcat.
  if [ $# -eq 0 ]; then
    if command -v batcat >/dev/null 2>&1; then
      batcat
    else
      builtin cat
    fi
    return $?
  fi

  # For each file given, ensure it exists.
  for file in "$@"; do
    if [ ! -f "$file" ]; then
      echo "Error: File '$file' not found." >&2
      return 1
    fi
  done

  # If batcat is available, try to display the files.
  if command -v batcat >/dev/null 2>&1; then
    if ! batcat "$@"; then
      echo "Warning: 'batcat' encountered an error, falling back to 'cat'." >&2
      builtin cat "$@"
    fi
  else
    # Fall back to the built-in cat if batcat is not found.
    builtin cat "$@"
  fi
}

# Aliases to override common commands with our enhanced function
alias cat='bat'
alias less='bat'

function cd() {
  # If no arguments provided, go to the home directory using the built-in cd
  if [ $# -eq 0 ]; then
    builtin cd ~
    return $?
  fi

  # Special case: handle "cd -"
  if [ "$1" = "-" ]; then
    builtin cd "$@"
    return $?
  fi

  # If the provided path is an existing directory, use the built-in cd
  if [ -d "$1" ]; then
    builtin cd "$@"
    return $?
  fi

  # Otherwise, attempt to navigate using zoxide
  if ! z "$@"; then
    # If zoxide fails, try the built-in cd as a fallback
    if ! builtin cd "$@"; then
      echo "Error: Directory '$@' not found" >&2
      return 1
    fi
  fi
}

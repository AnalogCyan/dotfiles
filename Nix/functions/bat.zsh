### bat wrapper & aliases for macOS only ###
if command -v bat >/dev/null 2>&1; then

  # Wrapper function to call the real bat binary, with sensible fallbacks
  bat() {
    # If no args, read from stdin (always use pager)
    if [[ $# -eq 0 ]]; then
      command bat --paging=always
      return $?
    fi

    # Verify each file exists
    for f in "$@"; do
      [[ -f $f ]] || { echo "bat: file '$f' not found." >&2; return 1; }
    done

    # Try bat, fall back to builtin cat on error
    if ! command bat "$@"; then
      echo "⚠️ bat encountered an error; falling back to builtin cat" >&2
      builtin cat "$@"
    fi
  }

  # Override the classics
  alias cat='bat'
  alias less='bat --paging=always'

fi

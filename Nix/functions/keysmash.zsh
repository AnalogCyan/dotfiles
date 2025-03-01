# Generates a configurable 'keysmash' string and copies it to clipboard
# Usage: keysmash [length]
# Example: keysmash 30

function keysmash() {
  local length=${1:-20} # Default length of 20 if not specified
  local charset="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!?.,;"

  # Validate input is a positive number
  if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 1 ]; then
    echo "Error: Length must be a positive number" >&2
    return 1
  fi

  # Generate keysmash using improved entropy source
  if [[ "$(uname)" == "Darwin" ]]; then
    # Use macOS native random source
    local result=$(LC_ALL=C tr -dc "$charset" </dev/random | fold -w "$length" | head -n 1)
  else
    # Fallback to urandom for other systems
    local result=$(LC_ALL=C tr -dc "$charset" </dev/urandom | fold -w "$length" | head -n 1)
  fi

  # Print result and copy to clipboard
  echo "$result"
  if command -v pbcopy >/dev/null 2>&1; then
    echo -n "$result" | pbcopy
    echo "Copied to clipboard!"
  elif command -v xclip >/dev/null 2>&1; then
    echo -n "$result" | xclip -selection clipboard
    echo "Copied to clipboard!"
  else
    echo "Warning: Clipboard tools not found, output not copied"
  fi
}

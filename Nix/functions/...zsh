# Enhanced directory navigation with multiple level support
# Usage: .. [number]
# Example: .. 3 (goes up 3 directories)

function ..() {
  local levels=${1:-1} # Default to 1 level if not specified
  local path=""

  # Validate input is a positive number
  if ! [[ "$levels" =~ ^[0-9]+$ ]]; then
    echo "Error: Please provide a positive number" >&2
    return 1
  fi

  # Build the path string
  for ((i = 0; i < levels; i++)); do
    path="../$path"
  done

  # Remove trailing slash
  path=${path%/}

  # Change directory and handle errors
  if ! cd "$path" 2>/dev/null; then
    echo "Error: Cannot go up $levels director$((levels > 1 ? 'ies' : 'y'))" >&2
    return 1
  fi

  # Show current location
  pwd
}

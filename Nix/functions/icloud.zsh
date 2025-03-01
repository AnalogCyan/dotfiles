# Creates a shortcut to iCloud directory and provides easy access via 'icloud' alias
# Usage: iCloud (run once to set up), then use 'icloud' to navigate

function iCloud() {
  local iCloudPath="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
  local shortcutPath="$HOME/iCloud"

  # Check if running on macOS
  if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: This function is only supported on macOS" >&2
    return 1
  fi

  # Verify iCloud directory exists and is accessible
  if [[ ! -d "${iCloudPath}" ]]; then
    echo "Error: iCloud directory not found at ${iCloudPath}" >&2
    echo "Please ensure you are signed into iCloud and it is properly synced" >&2
    return 1
  fi

  # Create or update shortcut
  if [[ -L "${shortcutPath}" && "$(readlink "${shortcutPath}")" != "${iCloudPath}" ]]; then
    echo "Updating existing iCloud shortcut..."
    rm "${shortcutPath}"
  fi

  if [[ ! -e "${shortcutPath}" ]]; then
    ln -s "${iCloudPath}" "${shortcutPath}" || {
      echo "Error: Failed to create iCloud shortcut" >&2
      return 1
    }
    echo "Created iCloud shortcut at ${shortcutPath}"
  fi

  # Create alias if it doesn't exist
  if ! alias icloud >/dev/null 2>&1; then
    alias icloud="cd ${shortcutPath}"
    echo "Created 'icloud' alias for quick access"
  fi

  echo "iCloud setup complete. Use 'icloud' command to access your iCloud directory."
}

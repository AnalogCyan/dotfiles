# This script creates a shortcut to the iCloud directory if it doesn't exist, and assigns an alias 'icloud' to cd into iCloud directory.

function iCloud() {
  iCloudPath="$HOME/Library/Mobile\ Documents/com~apple~CloudDocs"
  shortcutPath="$HOME/iCloud"

  # Checks if iCloud directory exists
  if [ ! -d "${iCloudPath}" ]; then
    echo "iCloud directory ${iCloudPath} not found."
    return 1
  fi

  # Checks if ~/iCloud shortcut exists, otherwise creates it
  if [ ! -d "${shortcutPath}" ]; then
    ln -s "${iCloudPath}" "${shortcutPath}"
  fi

  # Creates 'icloud' alias to cd into iCloud directory
  alias icloud="cd ${shortcutPath}"
}

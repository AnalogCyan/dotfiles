function zsh_greeting() {
  clear

  # Display system information
  if command -v pfetch >/dev/null 2>&1; then
    pfetch
  fi

  # Display outdated Homebrew packages
  if command -v brew >/dev/null 2>&1; then
    local outdated_output outdated_count
    outdated_output=$(HOMEBREW_NO_AUTO_UPDATE=1 brew outdated 2>&1)
    [[ "$outdated_output" == *"already locked"* || "$outdated_output" == *"already running"* ]] && return
    outdated_count=$(echo "$outdated_output" | grep -v '^Error' | wc -l | xargs)
    if (( outdated_count > 0 )); then
      echo "You have ${outdated_count} outdated Homebrew package(s)."
    fi
  fi
}

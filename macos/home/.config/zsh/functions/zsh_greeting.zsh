function zsh_greeting() {
  clear

  # Display system information
  if command -v pfetch >/dev/null 2>&1; then
    pfetch
  fi

  # Display outdated Homebrew packages
  if command -v brew >/dev/null 2>&1; then
    local outdated_count
    outdated_count=$(HOMEBREW_NO_AUTO_UPDATE=1 brew outdated 2>/dev/null | wc -l | xargs)
    if (( outdated_count > 0 )); then
      echo "You have ${outdated_count} outdated Homebrew package(s)."
    fi
  fi
}

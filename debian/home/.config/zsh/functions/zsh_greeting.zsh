function zsh_greeting() {
  clear

  # Display system information
  if command -v pfetch >/dev/null 2>&1; then
    pfetch
  fi

  # Display outdated apt packages
  if command -v apt >/dev/null 2>&1; then
    local outdated_count
    outdated_count=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
    if (( outdated_count > 0 )); then
      echo "You have ${outdated_count} upgradable apt package(s)."
    fi
  fi
}

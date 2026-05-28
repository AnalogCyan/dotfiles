zsh_greeting() {
  clear

  (( $+commands[pfetch] )) && pfetch

  if (( $+commands[brew] )); then
    local outdated_output
    outdated_output=$(HOMEBREW_NO_AUTO_UPDATE=1 brew outdated 2>/dev/null)
    if [[ "$outdated_output" != *"already locked"* && "$outdated_output" != *"already running"* ]]; then
      local -a lines=(${(f)outdated_output})
      local -a filtered=(${lines:#Error*})
      local count=${#filtered}
      (( count > 0 )) && print "You have ${count} outdated Homebrew package(s)."
    fi
  fi

  if (( $+commands[apt] )); then
    local count
    count=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
    (( count > 0 )) && print "You have ${count} upgradable apt package(s)."
  fi
}

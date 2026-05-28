zsh_greeting() {
  clear
  (( $+commands[pfetch] )) && pfetch

  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  local cache_file="${cache_dir}/update_checks_${HOST:-local}"
  mkdir -p "${cache_dir}"

  # Show cache immediately
  [[ -f "$cache_file" ]] && command cat "$cache_file"

  # Check cache age
  local last_update=0
  if [[ -f "$cache_file" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      last_update=$(stat -f "%m" "$cache_file" 2>/dev/null || echo 0)
    else
      last_update=$(stat -c "%Y" "$cache_file" 2>/dev/null || echo 0)
    fi
  fi

  local now
  now=$(date +%s)
  local age=$(( now - last_update ))

  # Trigger background update if cache is missing or > 4 hours old
  if [[ ! -f "$cache_file" || $age -gt 14400 ]]; then
    (
      local brew_count=0
      local apt_count=0
      local temp_file="${cache_file}.tmp.$$"
      local output=""
      local success=0

      if (( $+commands[brew] )); then
        local brew_outdated
        brew_outdated=$(HOMEBREW_NO_AUTO_UPDATE=1 brew outdated 2>/dev/null)
        local rc=$?
        # brew outdated exits 0 (no updates) or 1 (has updates) on success
        if [[ $rc -eq 0 || $rc -eq 1 ]]; then
          local -a lines=(${(f)brew_outdated})
          local -a filtered=(${lines:#Error*})
          brew_count=${#filtered}
          success=1
        fi
      fi

      if (( $+commands[apt] )); then
        local apt_outdated
        apt_outdated=$(apt list --upgradable 2>/dev/null)
        if [[ $? -eq 0 ]]; then
          apt_count=$(print "$apt_outdated" | grep -c upgradable)
          success=1
        fi
      fi

      # Only write cache if at least one check succeeded (prevent lock pollution)
      if [[ $success -eq 1 ]]; then
        (( brew_count > 0 )) && output+="You have ${brew_count} outdated Homebrew package(s).\n"
        (( apt_count > 0 )) && output+="You have ${apt_count} upgradable apt package(s).\n"

        print -rn "$output" > "$temp_file"
        mv -f "$temp_file" "$cache_file" 2>/dev/null || rm -f "$temp_file"
      fi
    ) >/dev/null 2>&1 &!
  fi
}

#!/bin/zsh
# =============================================================================
# .zlogin — Interactive Login Shell Greeting
# Wraps pfetch-rs with custom package update line
# =============================================================================

# Only run for interactive login shells
[[ -o interactive ]] || return

# Clear the terminal before printing
clear

# ---------------------------------------------------------------------------
# PFETCH-RS OUTPUT
# ---------------------------------------------------------------------------

# Run pfetch-rs if available
if (( $+commands[pfetch] )); then
  command pfetch
else
  # Fallback minimal display if pfetch-rs not installed yet
  print
  print "${USER}@${HOST%%.*}"
  print
fi

# ---------------------------------------------------------------------------
# PACKAGE UPDATE LINE (appended below pfetch output)
# ---------------------------------------------------------------------------

local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
local cache_file="${cache_dir}/update_checks_${HOST:-local}"
local lock_file="${cache_file}.lock"
mkdir -p "${cache_dir}"

# Show cached results immediately
if [[ -f "$cache_file" ]]; then
  local pkg_line
  pkg_line=$(command cat "$cache_file" 2>/dev/null)
  [[ -n "$pkg_line" ]] && printf "            pkgs    %s\n\n" "$pkg_line"
fi

# Skip background check if another shell is updating
[[ -f "$lock_file" ]] && return

# Check cache age (4 hours = 14400 seconds)
local last_update=0
if [[ -f "$cache_file" ]]; then
  if [[ "$OSTYPE" == darwin* ]]; then
    last_update=$(stat -f "%m" "$cache_file" 2>/dev/null || print 0)
  else
    last_update=$(stat -c "%Y" "$cache_file" 2>/dev/null || print 0)
  fi
fi

local check_now check_age
check_now=$(date +%s)
check_age=$(( check_now - last_update ))

# Trigger background update if stale
if [[ ! -f "$cache_file" || $check_age -gt 14400 ]]; then
  {
    touch "$lock_file"
    local brew_count=0 apt_count=0 output="" success=0

    # Homebrew check
    if (( $+commands[brew] )); then
      local brew_outdated
      brew_outdated=$(HOMEBREW_NO_AUTO_UPDATE=1 timeout 30 brew outdated 2>/dev/null)
      local rc=$?
      if [[ $rc -eq 0 || $rc -eq 1 ]]; then
        local -a lines=(${(f)brew_outdated})
        local -a filtered=(${lines:#Error*})
        brew_count=${#filtered}
        success=1
      fi
    fi

    # Apt check
    if (( $+commands[apt] )); then
      local apt_outdated
      apt_outdated=$(apt list --upgradable 2>/dev/null)
      if [[ $? -eq 0 ]]; then
        apt_count=$(print "$apt_outdated" | grep -cv '^Listing')
        success=1
      fi
    fi

    # Write cache only if we got valid data
    if [[ $success -eq 1 ]]; then
      (( brew_count > 0 )) && output+="${brew_count} brew outdated "
      (( apt_count > 0 )) && output+="${apt_count} apt upgradable"
      output="${output% }"  # trim trailing space

      local temp_file="${cache_file}.tmp.$$"
      print -n "$output" > "$temp_file"
      mv -f "$temp_file" "$cache_file" 2>/dev/null || rm -f "$temp_file"
    fi

    rm -f "$lock_file"
  } &!
fi

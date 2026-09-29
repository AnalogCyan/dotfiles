#!/usr/bin/env bash
# shellcheck disable=SC1091  # /etc/os-release is only sourced at runtime
# =============================================================================
#
#  Dotfiles Installer for macOS and Debian (Trixie)
#
#  Author: AnalogCyan
#  License: Unlicense
#
# =============================================================================

# Targets the stock macOS bash 3.2: no associative arrays, mapfile or
# namerefs, and empty arrays are expanded with ${a[@]+"${a[@]}"} under set -u.
set -uo pipefail
IFS=$'\n\t'

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Installs dotfiles and configures a macOS or Debian environment. Run it in a
terminal to pick steps and optional packages interactively.

Options:
  -n, --dry-run   Show what each step would change, without changing anything
  -y, --yes       No prompts: run every step, skip optional packages, keep a
                  non-empty ~/Downloads, continue on non-Debian Linux
  -h, --help      Show this help message and exit

Environment:
  NO_COLOR        Disable colors
EOF
}

DRY_RUN=0
ASSUME_YES=0

while [[ "${#}" -gt 0 ]]; do
  case "${1}" in
    -n|--dry-run) DRY_RUN=1 ;;
    -y|--yes)     ASSUME_YES=1 ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "Unknown option: ${1}" >&2; echo >&2; usage >&2; exit 1 ;;
  esac
  shift
done

# =============================================================================
# ENVIRONMENT
# =============================================================================

OS="$(uname -s)"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}"
CURRENT_USER="${USER:-$(id -un)}"

# Kept out of /tmp, which is RAM-backed on trixie and cleared on reboot
LOG_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/dotfiles"
LOG_FILE="${LOG_DIR}/install-$(date +%Y%m%d-%H%M%S).log"
WORK_DIR=""

# TTY means a terminal that can take cursor movement and the alternate screen
TTY=0
[[ -t 0 && -t 1 && -n "${TERM:-}" && "${TERM}" != "dumb" ]] && TTY=1
INTERACTIVE="${TTY}"
(( ASSUME_YES )) && INTERACTIVE=0

# =============================================================================
# CONFIGURATION
# =============================================================================

BREW_FORMULAE=(
  "anomalyco/tap/opencode-v2"
  "bat"
  "btop"
  "chojs23/tap/concord"
  "ctop"
  "dust"
  "eza"
  "fd"
  "forgejo-cli"
  "fortune"
  "fzf"
  "gh"
  "git"
  "go"
  "gromgit/brewtils/taproom"
  "helix"
  "imagemagick"
  "lazygit"
  "mole"
  "mpv"
  "neurosnap/tap/zmx"
  "nmap"
  "node"
  "pandoc"
  "philocalyst/tap/caligula"
  "python@3.13"
  "ripgrep"
  "rsync"
  "sevenzip"
  "shellcheck"
  "starship"
  "tmux"
  "wget"
  "xz"
  "yt-dlp"
  "zoxide"
  "zsh"
  croc
  pfetch-rs
  yazi
)

BREW_CASKS=(
  "1password"
  "1password-cli"
  "balenaetcher"
  "chatgpt"
  "claude"
  "cleanshot"
  "codex"
  "crystalfetch"
  "discord"
  "firefox@beta"
  "ghostty"
  "google-chrome@canary"
  "iina"
  "keka"
  "kekaexternalhelper"
  "mactracker"
  "mole-app"
  "obsidian"
  "orbstack"
  "raspberry-pi-imager"
  "t3-code@nightly"
  "tailscale-app"
  "transmission"
  "utm"
  "zed@preview"
)

BREW_FORMULAE_OPTIONAL=(
  "cdrtools:CD/DVD burning and ISO building (mkisofs)"
  "cmake:C/C++ build system"
  "colima:Docker runtime in a Lima VM"
  "f3:Fake-capacity flash drive tester"
  "gifsicle:GIF optimizer and editor"
  "make:GNU make (as gmake)"
  "powershell:PowerShell (pwsh)"
  "qpdf:Inspect, repair and transform PDFs"
  "scrcpy:Mirror and control Android over USB"
  "sox:Audio conversion and effects"
  "sshpass:Non-interactive SSH password auth"
  "zig:Zig compiler"
)

BREW_CASKS_OPTIONAL=(
  "android-platform-tools:adb and fastboot (needed by scrcpy)"
  "gimp:Image editor"
  "inkscape:Vector graphics editor"
  "obs:Screen recording and streaming"
  "steam:Game store"
  "typeless:AI voice dictation"
)

declare -a APT_PACKAGES=(
  bat
  btop
  ca-certificates
  curl
  eza
  fd-find
  fontconfig
  fortune-mod
  fzf
  gh
  git
  gnupg
  hx
  jq
  lazygit
  nvme-cli
  ripgrep
  rsync
  starship
  tmux
  unzip
  xz-utils
  yt-dlp
  zoxide
  zsh
)

# Filled in by the package picker
SELECTED_FORMULAE_OPTIONAL=()
SELECTED_CASKS_OPTIONAL=()
PACKAGES_VISITED=0

# Set by the planner when ~/Downloads is a non-empty real directory
REPLACE_DOWNLOADS=0

# =============================================================================
# UI
# =============================================================================

ui_init() {
  C_RESET="" C_BOLD="" C_DIM="" C_RED="" C_GREEN="" C_YELLOW=""
  C_BLUE="" C_MAGENTA="" C_CYAN=""
  if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-dumb}" != "dumb" ]]; then
    C_RESET=$'\e[0m' C_BOLD=$'\e[1m' C_DIM=$'\e[2m'
    C_RED=$'\e[31m' C_GREEN=$'\e[32m' C_YELLOW=$'\e[33m'
    C_BLUE=$'\e[34m' C_MAGENTA=$'\e[35m' C_CYAN=$'\e[36m'
  fi

  case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
    *UTF-8*|*utf-8*|*UTF8*|*utf8*)
      G_PTR="❯" G_ON="◉" G_OFF="○" G_OK="✓" G_WARN="▲" G_FAIL="✗"
      G_DOT="·" G_ARROW="›" G_UP="↑" G_DOWN="↓" G_BULLET="•"
      G_RULE="─" G_ELL="…"
      SPIN=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
      ;;
    *)
      G_PTR=">" G_ON="[x]" G_OFF="[ ]" G_OK="+" G_WARN="!" G_FAIL="x"
      G_DOT="|" G_ARROW=">" G_UP="^" G_DOWN="v" G_BULLET="*"
      G_RULE="-" G_ELL="~"
      SPIN=("|" "/" "-" "\\")
      ;;
  esac
}

SCREEN_ALT=0
CURSOR_HIDDEN=0

screen_enter() {
  (( TTY )) || return 0
  printf '\e[?1049h\e[H\e[2J'
  SCREEN_ALT=1
  cursor_hide
}

screen_leave() {
  (( SCREEN_ALT )) || return 0
  printf '\e[?1049l'
  SCREEN_ALT=0
}

cursor_hide() { (( TTY )) && { printf '\e[?25l'; CURSOR_HIDDEN=1; }; return 0; }
cursor_show() { (( CURSOR_HIDDEN )) && { printf '\e[?25h'; CURSOR_HIDDEN=0; }; return 0; }

term_size() {
  local size
  size=$( { stty size </dev/tty; } 2>/dev/null ) || size=""
  ROWS="${size%% *}"
  COLS="${size##* }"
  [[ "${ROWS}" =~ ^[0-9]+$ && "${ROWS}" -gt 0 ]] || ROWS=24
  [[ "${COLS}" =~ ^[0-9]+$ && "${COLS}" -gt 0 ]] || COLS=80
}

# Sets KEY to up, down, space, enter, all, back, quit, yes, no, diff, tick or other
read_key() {
  local k="" rest=""
  KEY="other"
  if ! IFS= read -rsn1 -t 1 k </dev/tty; then
    KEY="tick"
    return
  fi
  case "${k}" in
    $'\e')
      IFS= read -rsn2 -t 1 rest </dev/tty || rest=""
      case "${rest}" in
        "[A"|"OA") KEY="up" ;;
        "[B"|"OB") KEY="down" ;;
        "")        KEY="back" ;;
      esac
      ;;
    " ")   KEY="space" ;;
    "")    KEY="enter" ;;
    k|K)   KEY="up" ;;
    j|J)   KEY="down" ;;
    a|A)   KEY="all" ;;
    b|B|h|H) KEY="back" ;;
    q|Q)   KEY="quit" ;;
    y|Y)   KEY="yes" ;;
    n|N)   KEY="no" ;;
    d|D)   KEY="diff" ;;
  esac
}

# Text width for prose, capped so wide terminals stay readable
text_width() {
  local width=$(( COLS - ${1:-4} ))
  (( width > 76 )) && width=76
  printf '%s' "${width}"
}

rule() {
  local width=$(( COLS - 4 ))
  (( width > 72 )) && width=72
  (( width < 1 )) && width=1
  repeat_char "${G_RULE}" "${width}"
}

tildify() {
  case "$1" in
    "${HOME}"|"${HOME}"/*) printf '%s%s' "~" "${1#"${HOME}"}" ;;
    *) printf '%s' "$1" ;;
  esac
}

# in_list needle item... succeeds if needle is one of the items
in_list() {
  local needle="$1" item
  shift
  for item in "$@"; do
    [[ "${item}" == "${needle}" ]] && return 0
  done
  return 1
}

join_by() {
  local sep="$1" out="" item
  shift
  for item in "$@"; do out+="${out:+${sep}}${item}"; done
  printf '%s' "${out}"
}

repeat_char() {
  local out="" i
  for (( i = 0; i < $2; i++ )); do out+="$1"; done
  printf '%s' "${out}"
}

format_duration() {
  local s="$1"
  if (( s < 1 )); then
    printf '<1s'
  elif (( s < 60 )); then
    printf '%ds' "${s}"
  else
    printf '%dm %02ds' $(( s / 60 )) $(( s % 60 ))
  fi
}

strip_ansi() {
  LC_ALL=C sed -e $'s/\e\\[[0-9;?]*[A-Za-z]//g' -e $'s/\e[()][A-Za-z0-9]//g'
}

system_info() {
  local os_name arch
  arch="$(uname -m)"
  case "${OS}" in
    Darwin) os_name="macOS $(sw_vers -productVersion 2>/dev/null)" ;;
    Linux)
      os_name="Linux"
      if [[ -r /etc/os-release ]]; then
        os_name="$(. /etc/os-release && printf '%s' "${PRETTY_NAME:-${NAME:-Linux}}")"
      fi
      ;;
    *) os_name="${OS}" ;;
  esac
  SYS_INFO="$(join_by " ${G_DOT} " "${os_name}" "${arch}" "$(hostname -s 2>/dev/null || hostname)")"
}

# Frame builder for full-screen views: every line clears to end of line so
# redraws never leave stale characters behind.
FRAME=""
FRAME_LINES=0
BODY=()
BODY_MODE=0
fl() {
  if (( BODY_MODE )); then
    BODY+=("$1")
    return
  fi
  FRAME+="$1"$'\e[K\n'
  FRAME_LINES=$(( FRAME_LINES + 1 ))
}

# Emits buffered body lines, trimming them to the space left above the footer
flush_body() {
  local room i n="${#BODY[@]}"
  BODY_MODE=0
  room=$(( ROWS - FRAME_LINES - $(footer_lines) ))
  if (( n <= room )); then
    for (( i = 0; i < n; i++ )); do fl "${BODY[i]}"; done
  else
    for (( i = 0; i < room - 1; i++ )); do fl "${BODY[i]}"; done
    fl "  ${C_DIM}${G_DOWN} $(( n - room + 1 )) more lines; enlarge the terminal to see them${C_RESET}"
  fi
  BODY=()
}

# Truncate plain text to a width, marking the cut
fit() {
  local text="$1" width="$2"
  if (( width < 4 )); then
    printf '%s' "${text:0:${width}}"
  elif (( ${#text} > width )); then
    printf '%s%s' "${text:0:$(( width - 1 ))}" "${G_ELL}"
  else
    printf '%s' "${text}"
  fi
}

# Word-wrap plain text to a width, one output line per wrapped line
wrap() {
  local text="$1" width="$2" line="" word
  local IFS=' '
  for word in ${text}; do
    if [[ -z "${line}" ]]; then
      line="${word}"
    elif (( ${#line} + 1 + ${#word} <= width )); then
      line+=" ${word}"
    else
      printf '%s\n' "$(fit "${line}" "${width}")"
      line="${word}"
    fi
  done
  [[ -n "${line}" ]] && printf '%s\n' "$(fit "${line}" "${width}")"
  return 0
}

# Wrap key hints between items rather than mid-hint
wrap_hints() {
  local width="$1" line="" item sep=" ${G_DOT} "
  shift
  for item in "$@"; do
    if [[ -z "${line}" ]]; then
      line="${item}"
    elif (( ${#line} + ${#sep} + ${#item} <= width )); then
      line+="${sep}${item}"
    else
      printf '%s\n' "${line}"
      line="${item}"
    fi
  done
  [[ -n "${line}" ]] && printf '%s\n' "${line}"
  return 0
}

MIN_COLS=50
MIN_ROWS=16

# Draws a notice instead of the screen when the terminal is too small
too_small() {
  (( COLS >= MIN_COLS && ROWS >= MIN_ROWS )) && return 1
  FRAME=$'\e[H' FRAME_LINES=0
  fl ""
  fl "  ${C_YELLOW}Terminal too small${C_RESET}"
  fl "  ${C_DIM}$(fit "Resize to at least ${MIN_COLS}x${MIN_ROWS} (now ${COLS}x${ROWS})." $(( COLS - 2 )))${C_RESET}"
  # No newline after the last line, or a full-height frame scrolls
  FRAME="${FRAME%$'\n'}"$'\e[J'
  printf '%s' "${FRAME}"
  return 0
}

frame_header() {
  local title="$1" subtitle="$2" badge="" badge_len=0 line
  if (( DRY_RUN )); then
    badge="  ${C_YELLOW}${C_BOLD}DRY RUN${C_RESET}"
    badge_len=9
  fi
  FRAME=$'\e[H' FRAME_LINES=0
  (( ROWS >= 24 )) && fl ""
  fl "  ${C_BOLD}${C_MAGENTA}dotfiles${C_RESET}  ${C_DIM}$(fit "${SYS_INFO}" $(( COLS - 14 - badge_len )))${C_RESET}${badge}"
  fl "  ${C_DIM}$(rule)${C_RESET}"
  fl "  ${BREADCRUMB}"
  (( ROWS >= 24 )) && fl ""
  fl "  ${C_BOLD}$(fit "${title}" $(( COLS - 4 )))${C_RESET}"
  if [[ -n "${subtitle}" ]]; then
    while IFS= read -r line; do
      fl "  ${C_DIM}${line}${C_RESET}"
    done < <(wrap "${subtitle}" "$(text_width)")
  fi
  fl ""
}

# Footer hints are passed as separate items so they wrap cleanly
FOOTER_HINTS=()
FOOTER_MSG=""

footer_lines() {
  local count=1
  [[ -n "${FOOTER_MSG}" ]] && count=$(( count + 1 ))
  count=$(( count + $(wrap_hints $(( COLS - 4 )) "${FOOTER_HINTS[@]}" | wc -l) ))
  printf '%s' "${count}"
}

frame_footer() {
  local line
  fl ""
  [[ -n "${FOOTER_MSG}" ]] && fl "  ${FOOTER_MSG}"
  while IFS= read -r line; do
    fl "  ${C_DIM}${line}${C_RESET}"
  done < <(wrap_hints $(( COLS - 4 )) "${FOOTER_HINTS[@]}")
  # No newline after the last line, or a full-height frame scrolls
  FRAME="${FRAME%$'\n'}"$'\e[J'
  printf '%s' "${FRAME}"
}

set_hints() {
  FOOTER_HINTS=("$@")
  (( CAN_GO_BACK )) && FOOTER_HINTS+=("b back")
  FOOTER_HINTS+=("q quit")
}

# Breadcrumb over the wizard screens, current one highlighted
WIZARD_SCREENS=()
set_breadcrumb() {
  local current="$1" name parts=()
  for name in ${WIZARD_SCREENS[@]+"${WIZARD_SCREENS[@]}"}; do
    if [[ "${name}" == "${current}" ]]; then
      parts+=("${C_CYAN}${C_BOLD}${name}${C_RESET}")
    else
      parts+=("${C_DIM}${name}${C_RESET}")
    fi
  done
  BREADCRUMB="$(join_by " ${C_DIM}${G_ARROW}${C_RESET} " ${parts[@]+"${parts[@]}"})"
}

# Checklist over CL_LABELS/CL_DESCS/CL_ON/CL_TAGS. CL_ON holds 1 or 0, or "h"
# for a section header row. Returns 0 on enter and 1 on back.
CL_LABELS=() CL_DESCS=() CL_ON=() CL_TAGS=()
CL_CUR=0 CL_TOP=0 CL_MSG=""
CL_LIVE_STEPS=0
CAN_GO_BACK=0

ui_checklist() {
  local title="$1" subtitle="$2" n="${#CL_LABELS[@]}" i step last_size=""
  (( CL_CUR < n )) || CL_CUR=0
  while [[ "${CL_ON[CL_CUR]}" == "h" ]]; do CL_CUR=$(( CL_CUR + 1 )); done

  while true; do
    term_size
    if [[ "${KEY:-}" != "tick" || "${ROWS}x${COLS}" != "${last_size}" ]]; then
      too_small || render_checklist "${title}" "${subtitle}"
      last_size="${ROWS}x${COLS}"
    fi
    read_key
    [[ "${KEY}" != "tick" ]] && CL_MSG=""
    case "${KEY}" in
      up|down)
        step=1
        [[ "${KEY}" == "up" ]] && step=-1
        i="${CL_CUR}"
        while true; do
          i=$(( i + step ))
          (( i < 0 || i >= n )) && break
          if [[ "${CL_ON[i]}" != "h" ]]; then CL_CUR="${i}"; break; fi
        done
        ;;
      space)
        if [[ "${CL_ON[CL_CUR]}" == "1" ]]; then CL_ON[CL_CUR]=0; else CL_ON[CL_CUR]=1; fi
        ;;
      all)
        local any_off=0 v
        for (( i = 0; i < n; i++ )); do [[ "${CL_ON[i]}" == "0" ]] && any_off=1; done
        v=0
        (( any_off )) && v=1
        for (( i = 0; i < n; i++ )); do [[ "${CL_ON[i]}" != "h" ]] && CL_ON[i]="${v}"; done
        ;;
      enter) return 0 ;;
      back)  (( CAN_GO_BACK )) && return 1 ;;
      quit)  quit_wizard ;;
    esac
  done
}

render_checklist() {
  local title="$1" subtitle="$2" n="${#CL_LABELS[@]}" i lw=0 selected=0 total=0
  local visible end line name desc avail ptr mark tag dw=0 has_tags=0 sections=0

  for (( i = 0; i < n; i++ )); do
    (( ${#CL_LABELS[i]} > lw )) && lw="${#CL_LABELS[i]}"
    if [[ "${CL_ON[i]}" == "h" ]]; then
      (( i > 0 )) && sections=1
      continue
    fi
    (( ${#CL_DESCS[i]} > dw )) && dw="${#CL_DESCS[i]}"
    [[ -n "${CL_TAGS[i]:-}" ]] && has_tags=1
    total=$(( total + 1 ))
    [[ "${CL_ON[i]}" == "1" ]] && selected=$(( selected + 1 ))
  done

  if (( CL_LIVE_STEPS )); then
    STEP_ON=("${CL_ON[@]}")
    wizard_screens
    set_breadcrumb "Steps"
  fi
  FOOTER_MSG="${C_DIM}${selected} of ${total} selected${C_RESET}"
  [[ -n "${CL_MSG}" ]] && FOOTER_MSG="${C_YELLOW}$(fit "${CL_MSG}" $(( COLS - 4 )))${C_RESET}"
  set_hints "${G_UP}/${G_DOWN} move" "space toggle" "a all/none" "enter continue"

  frame_header "${title}" "${subtitle}"

  # Header, footer, two scroll indicators and a spare for section spacing
  local scrolls=0
  visible=$(( ROWS - FRAME_LINES - $(footer_lines) - sections ))
  if (( n + sections > visible )); then
    # Room for the two "more" indicators only when the list scrolls
    scrolls=1
    visible=$(( visible - 2 ))
  fi
  (( visible < 1 )) && visible=1
  (( CL_CUR < CL_TOP )) && CL_TOP="${CL_CUR}"
  (( CL_CUR >= CL_TOP + visible )) && CL_TOP=$(( CL_CUR - visible + 1 ))
  # Keep a section header visible above the first item in its section
  if (( CL_TOP > 0 )) && [[ "${CL_ON[CL_TOP - 1]}" == "h" ]] && (( CL_CUR < CL_TOP + visible - 1 )); then
    CL_TOP=$(( CL_TOP - 1 ))
  fi
  end=$(( CL_TOP + visible ))
  (( end > n )) && end="${n}"

  # Room for pointer, mark, label and the tag column
  avail=$(( COLS - lw - 12 ))
  (( has_tags )) && avail=$(( avail - 11 ))
  (( dw > avail )) && dw="${avail}"

  if (( CL_TOP > 0 )); then
    fl "    ${C_DIM}${G_UP} ${CL_TOP} more${C_RESET}"
  elif (( scrolls )); then
    fl ""
  fi

  for (( i = CL_TOP; i < end; i++ )); do
    if [[ "${CL_ON[i]}" == "h" ]]; then
      (( i > CL_TOP )) && fl ""
      fl "  ${C_BOLD}${C_BLUE}${CL_LABELS[i]}${C_RESET}"
      continue
    fi
    ptr=" "
    (( i == CL_CUR )) && ptr="${C_CYAN}${G_PTR}${C_RESET}"
    if [[ "${CL_ON[i]}" == "1" ]]; then
      mark="${C_GREEN}${G_ON}${C_RESET}"
    else
      mark="${C_DIM}${G_OFF}${C_RESET}"
    fi
    printf -v name "%-${lw}s" "${CL_LABELS[i]}"
    if (( i == CL_CUR )); then
      name="${C_BOLD}${name}${C_RESET}"
    elif [[ "${CL_ON[i]}" != "1" ]]; then
      name="${C_DIM}${name}${C_RESET}"
    fi
    tag="${CL_TAGS[i]:-}"
    desc="${CL_DESCS[i]:-}"
    if (( dw < 8 )); then
      desc=""
    else
      desc="$(fit "${desc}" "${dw}")"
    fi
    (( has_tags && ${#desc} < dw )) && desc+="$(repeat_char " " $(( dw - ${#desc} )))"
    line="  ${ptr} ${mark} ${name}  ${C_DIM}${desc}${C_RESET}"
    case "${tag}" in
      sudo)      line+="  ${C_YELLOW}${C_DIM}${tag}${C_RESET}" ;;
      installed) line+="  ${C_GREEN}${C_DIM}${tag}${C_RESET}" ;;
      ?*)        line+="  ${C_DIM}${tag}${C_RESET}" ;;
    esac
    fl "${line}"
  done

  if (( end < n )); then
    fl "    ${C_DIM}${G_DOWN} $(( n - end )) more${C_RESET}"
  elif (( scrolls )); then
    fl ""
  fi

  frame_footer
}

US=$'\x1f'

# Full-screen yes/no question. Returns 0 for yes, 1 for no, 2 for back.
ui_question() {
  local title="$1" body="$2" default="$3" last_size="" line
  KEY=""
  while true; do
    term_size
    if [[ "${KEY}" != "tick" || "${ROWS}x${COLS}" != "${last_size}" ]]; then
      last_size="${ROWS}x${COLS}"
      too_small && { read_key; [[ "${KEY}" == "quit" ]] && quit_wizard; continue; }
      frame_header "${title}" ""
      # Body lines are "color<US>text" so wrapping never splits an escape
      local color text wrapped
      while IFS=$'\x1f' read -r color text; do
        if [[ -z "${text}" ]]; then fl ""; continue; fi
        while IFS= read -r wrapped; do
          fl "  ${color}${wrapped}${C_RESET}"
        done < <(wrap "${text}" "$(text_width)")
      done <<<"${body}"
      local yes_label="y yes" no_label="n no"
      if [[ "${default}" == "y" ]]; then yes_label="Y yes"; else no_label="N no"; fi
      FOOTER_MSG=""
      set_hints "${yes_label}" "${no_label}" "enter default (${default})"
      frame_footer
    fi
    read_key
    case "${KEY}" in
      yes)   return 0 ;;
      no)    return 1 ;;
      enter) [[ "${default}" == "y" ]] && return 0; return 1 ;;
      back)  (( CAN_GO_BACK )) && return 2 ;;
      quit)  quit_wizard ;;
    esac
  done
}

quit_wizard() {
  screen_leave
  cursor_show
  echo "Cancelled. Nothing was changed."
  exit 130
}

pager() {
  if command -v less >/dev/null 2>&1; then
    less -R
  elif command -v more >/dev/null 2>&1; then
    more
  else
    cat
  fi
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Step functions write these to the log; the TUI shows a live tail of it.
log_info()    { echo "INFO:    $*"; }
log_success() { echo "SUCCESS: $*"; }
log_warning() { echo "WARNING: $*"; }
log_error()   { echo "ERROR:   $*"; }

curl_https() { curl --proto '=https' --tlsv1.2 -fsSL "$@"; }

# Non-interactive apt-get that keeps existing config files and waits for the
# dpkg lock (unattended-upgrades often holds it on a fresh install)
apt_get() {
  sudo DEBIAN_FRONTEND=noninteractive apt-get -y \
    -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold \
    -o DPkg::Lock::Timeout=300 "$@"
}

# GitHub API request; GITHUB_TOKEN, when set, lifts the 60/hour anonymous limit
github_api() {
  local auth=()
  [[ -n "${GITHUB_TOKEN:-}" ]] && auth=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  curl_https ${auth[@]+"${auth[@]}"} -H "Accept: application/vnd.github+json" "https://api.github.com/$1"
}

# Latest release tag from the releases/latest redirect, which has no API quota
github_latest_tag() {
  local url
  url="$(curl_https -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest")" || return 1
  [[ "${url}" == */tag/* ]] || return 1
  printf '%s' "${url##*/}"
}

load_brew_env() {
  local brew_bin
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "${brew_bin}" ]]; then
      eval "$("${brew_bin}" shellenv)"
      return 0
    fi
  done
  return 0
}

login_shell() {
  case "${OS}" in
    Darwin) dscl . -read "/Users/${CURRENT_USER}" UserShell 2>/dev/null | awk '{print $2}' ;;
    Linux)  getent passwd "${CURRENT_USER}" 2>/dev/null | cut -d: -f7 ;;
  esac
}

target_zsh() {
  case "${OS}" in
    Darwin) command -v brew >/dev/null 2>&1 && printf '%s' "$(brew --prefix)/bin/zsh" ;;
    Linux)  command -v zsh 2>/dev/null || true ;;
  esac
}

# Sorted dotfile paths relative to home/, excluding Finder metadata
dotfile_list() {
  (cd "${DOTFILES_DIR}/home" && find . -type f ! -name .DS_Store | sed 's|^\./||' | LC_ALL=C sort)
}

# Sets DF_NEW, DF_CHANGED and DF_SAME
dotfile_changes() {
  local rel
  DF_NEW=() DF_CHANGED=() DF_SAME=0
  while IFS= read -r rel; do
    [[ -z "${rel}" ]] && continue
    if [[ ! -e "${HOME}/${rel}" ]]; then
      DF_NEW+=("${rel}")
    elif cmp -s "${DOTFILES_DIR}/home/${rel}" "${HOME}/${rel}"; then
      DF_SAME=$(( DF_SAME + 1 ))
    else
      DF_CHANGED+=("${rel}")
    fi
  done < <(dotfile_list)
}

# "+3 -1" for how deploying would change a live file
diff_counts() {
  local out adds dels
  out="$(diff "${HOME}/$1" "${DOTFILES_DIR}/home/$1" 2>/dev/null)"
  adds=$(printf '%s\n' "${out}" | grep -c '^>')
  dels=$(printf '%s\n' "${out}" | grep -c '^<')
  printf '+%s -%s' "${adds}" "${dels}"
}

# shellcheck disable=SC2088
show_dotfile_diff() {
  local rel
  {
    for rel in ${DF_CHANGED[@]+"${DF_CHANGED[@]}"}; do
      diff -u --label "~/${rel} (current)" --label "~/${rel} (dotfiles)" \
        "${HOME}/${rel}" "${DOTFILES_DIR}/home/${rel}" | colorize_diff
      echo
    done
    for rel in ${DF_NEW[@]+"${DF_NEW[@]}"}; do
      diff -u --label "~/${rel} (not present)" --label "~/${rel} (dotfiles)" \
        /dev/null "${DOTFILES_DIR}/home/${rel}" | colorize_diff
      echo
    done
  } | pager
}

colorize_diff() {
  if [[ -z "${C_RESET}" ]]; then
    cat
    return
  fi
  local line
  while IFS= read -r line; do
    case "${line}" in
      "+++"*|"---"*) printf '%s\n' "${C_BOLD}${line}${C_RESET}" ;;
      "+"*)          printf '%s\n' "${C_GREEN}${line}${C_RESET}" ;;
      "-"*)          printf '%s\n' "${C_RED}${line}${C_RESET}" ;;
      "@@"*)         printf '%s\n' "${C_CYAN}${line}${C_RESET}" ;;
      *)             printf '%s\n' "${line}" ;;
    esac
  done
}

# =============================================================================
# MACOS FUNCTIONS
# =============================================================================

install_updates_macos() {
  local status=0
  log_info "Checking for macOS system updates..."
  sudo softwareupdate -ia --force --verbose || {
    log_warning "Some macOS updates may have failed."
    status=1
  }

  if command -v brew >/dev/null 2>&1; then
    log_info "Updating Homebrew..."
    if ! brew update || ! brew upgrade || ! brew cleanup; then
      log_warning "Homebrew update/upgrade had issues."
      status=1
    fi
  fi

  if (( status == 0 )); then
    log_success "System update completed."
  else
    log_warning "System update finished with warnings."
  fi

  return "${status}"
}

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    log_info "Homebrew already installed."
    eval "$("$(brew --prefix)/bin/brew" shellenv)"
    return
  fi

  log_info "Installing Homebrew..."
  local script="${WORK_DIR}/homebrew-install.sh"
  if ! curl_https -o "${script}" https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh; then
    log_error "Failed to download the Homebrew installer."
    return 2
  fi
  NONINTERACTIVE=1 /bin/bash "${script}" || {
    log_error "Failed to install Homebrew."
    return 2
  }

  local brew_path
  if [[ -f /opt/homebrew/bin/brew ]]; then
    brew_path="/opt/homebrew/bin/brew"
  elif [[ -f /usr/local/bin/brew ]]; then
    brew_path="/usr/local/bin/brew"
  fi

  if [[ -n "${brew_path:-}" ]]; then
    if [[ ! -f "${HOME}/.zprofile" ]] || ! grep -qF "eval \"\$(${brew_path} shellenv)\"" "${HOME}/.zprofile"; then
      echo "eval \"\$(${brew_path} shellenv)\"" >>"${HOME}/.zprofile"
    fi
    eval "$("${brew_path}" shellenv)"
  fi

  log_success "Homebrew installed."
}

install_homebrew_packages() {
  local status=0
  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew is not installed. Run the Homebrew step first."
    return 2
  fi
  # The updates step already ran brew update
  step_selected install_updates_macos && export HOMEBREW_NO_AUTO_UPDATE=1

  log_info "Installing formulae..."
  brew install "${BREW_FORMULAE[@]}" || {
    log_warning "Some formulae failed."
    status=1
  }

  log_info "Installing casks..."
  brew install --cask "${BREW_CASKS[@]}" || {
    log_warning "Some casks failed."
    status=1
  }

  if (( ${#SELECTED_FORMULAE_OPTIONAL[@]} > 0 )); then
    log_info "Installing optional formulae..."
    brew install "${SELECTED_FORMULAE_OPTIONAL[@]}" || {
      log_warning "Some optional formulae failed."
      status=1
    }
  fi

  if (( ${#SELECTED_CASKS_OPTIONAL[@]} > 0 )); then
    log_info "Installing optional casks..."
    brew install --cask "${SELECTED_CASKS_OPTIONAL[@]}" || {
      log_warning "Some optional casks failed."
      status=1
    }
  fi

  if (( status == 0 )); then
    log_success "Packages installed."
  else
    log_warning "Package installation finished with warnings."
  fi

  return "${status}"
}

setup_icloud_links() {
  local status=0
  log_info "Creating iCloud symlinks..."
  ln -snf "${HOME}/Library/Mobile Documents/com~apple~CloudDocs" "${HOME}/iCloud" || {
    log_warning "Failed to create iCloud symlink."
    status=1
  }

  local downloads_target="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Downloads"
  if [[ -d "${downloads_target}" ]]; then
    if [[ -e "${HOME}/Downloads" && ! -L "${HOME}/Downloads" ]]; then
      if [[ -z "$(ls -A "${HOME}/Downloads" 2>/dev/null)" ]]; then
        rm -rf "${HOME}/Downloads"
      elif (( REPLACE_DOWNLOADS )); then
        rm -rf "${HOME}/Downloads"
      else
        log_info "Kept the non-empty Downloads directory as chosen."
        log_success "iCloud links configured."
        return "${status}"
      fi
    fi
    ln -snf "${downloads_target}" "${HOME}/Downloads" || {
      log_warning "Failed to create Downloads symlink."
      status=1
    }
  fi

  if (( status == 0 )); then
    log_success "iCloud links configured."
  else
    log_warning "iCloud link setup finished with warnings."
  fi

  return "${status}"
}

setup_ghostty_config() {
  local status=0
  log_info "Setting up Ghostty config..."
  mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
  ln -sf "$HOME/.config/ghostty/config.ghostty" \
    "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty" || {
    log_warning "Failed to set up Ghostty config."
    status=1
  }
  if (( status == 0 )); then
    log_success "Ghostty config set up."
  else
    log_warning "Ghostty config setup finished with warnings."
  fi
  return "${status}"
}

# =============================================================================
# DEBIAN FUNCTIONS
# =============================================================================

install_updates_debian() {
  local status=0
  log_info "Updating system..."
  # modernize-sources only exists in apt, not apt-get
  sudo apt -y modernize-sources || {
    log_warning "Failed to modernize sources."
    status=1
  }
  apt_get update || {
    log_warning "apt update failed"
    status=1
  }
  apt_get full-upgrade || {
    log_warning "apt full-upgrade had issues"
    status=1
  }
  apt_get autoremove || true
  apt_get autoclean || true
  if (( status == 0 )); then
    log_success "System update completed."
  else
    log_warning "System update finished with warnings."
  fi

  return "${status}"
}

install_apt_packages() {
  local status=0
  log_info "Installing packages..."
  apt_get install --no-install-recommends "${APT_PACKAGES[@]}" || {
    log_warning "Some packages failed to install."
    status=1
  }
  if (( status == 0 )); then
    log_success "Packages installed."
  else
    log_warning "Package installation finished with warnings."
  fi

  return "${status}"
}

install_pfetch_rs() {
  local status=0
  log_info "Installing pfetch-rs..."

  local arch pfetch_arch asset_url tmp_dir
  arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
  case "${arch}" in
    x86_64|amd64)  pfetch_arch="x86_64" ;;
    aarch64|arm64) pfetch_arch="aarch64" ;;
    *)
      log_warning "Unsupported architecture for pfetch-rs: ${arch}; skipping."
      return 1
      ;;
  esac

  asset_url="https://github.com/Gobidev/pfetch-rs/releases/latest/download/pfetch-linux-musl-${pfetch_arch}.tar.gz"

  log_info "Downloading pfetch-rs from ${asset_url}..."
  tmp_dir=$(mktemp -d)
  curl -fsSL "${asset_url}" -o "${tmp_dir}/pfetch.tar.gz" || {
    log_warning "Failed to download pfetch-rs."
    rm -rf "${tmp_dir}"
    return 1
  }

  tar -xzf "${tmp_dir}/pfetch.tar.gz" -C "${tmp_dir}" || {
    log_warning "Failed to extract pfetch-rs."
    rm -rf "${tmp_dir}"
    return 1
  }

  sudo install -m 755 "${tmp_dir}/pfetch" /usr/local/bin/pfetch || {
    log_warning "Failed to install pfetch-rs."
    status=1
  }

  rm -rf "${tmp_dir}"

  if (( status == 0 )); then
    log_success "pfetch-rs installed."
  else
    log_warning "pfetch-rs installation finished with warnings."
  fi

  return "${status}"
}

install_ghostty() {
  local status=0
  log_info "Installing Ghostty..."

  local arch deb_arch codename asset_url tmp_deb
  arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
  case "${arch}" in
    amd64|x86_64) deb_arch="amd64" ;;
    arm64|aarch64) deb_arch="arm64" ;;
    *)
      log_warning "Unsupported architecture: ${arch}"
      return 1
      ;;
  esac

  codename=$(. /etc/os-release && echo "$VERSION_CODENAME")

  # mkasberg is the only repo with arm64 + Forky builds. Asset names carry
  # the version, so read them off the release's asset list page, which
  # unlike the API has no anonymous rate limit.
  local tag path
  if tag="$(github_latest_tag mkasberg/ghostty-ubuntu)"; then
    path="$(curl_https "https://github.com/mkasberg/ghostty-ubuntu/releases/expanded_assets/${tag}" \
      | grep -oE "href=\"[^\"]*_${deb_arch}_${codename}\\.deb\"" | head -n1)"
    path="${path#href=\"}"
    path="${path%\"}"
    [[ -n "${path}" ]] && asset_url="https://github.com${path}"
  fi
  if [[ -z "${asset_url:-}" ]]; then
    asset_url=$(github_api "repos/mkasberg/ghostty-ubuntu/releases/latest" \
      | jq -r --arg arch "${deb_arch}" --arg codename "${codename}" \
        '.assets[] | select(.name | test("_" + $arch + "_" + $codename + "\\.deb$")) | .browser_download_url' \
      | head -n1)
  fi

  if [[ -z "${asset_url}" || "${asset_url}" == "null" ]]; then
    log_warning "No Ghostty .deb found for ${deb_arch}/${codename}"
    return 1
  fi

  log_info "Downloading Ghostty from ${asset_url}..."
  tmp_deb="${WORK_DIR}/ghostty.deb"
  curl -fsSL "${asset_url}" -o "${tmp_deb}" || {
    log_warning "Failed to download Ghostty."
    rm -f "${tmp_deb}"
    return 1
  }

  apt_get install "${tmp_deb}" || {
    log_warning "Failed to install the Ghostty package."
    status=1
  }

  rm -f "${tmp_deb}"

  if (( status == 0 )); then
    log_success "Ghostty installed."
  else
    log_warning "Ghostty installation finished with warnings."
  fi

  return "${status}"
}

install_zed() {
  local status=0
  log_info "Installing Zed..."
  local script="${WORK_DIR}/zed-install.sh"
  if ! curl_https -o "${script}" https://zed.dev/install.sh; then
    log_warning "Failed to download the Zed installer."
    return 1
  fi
  ZED_CHANNEL=preview sh "${script}" || {
    log_warning "Failed to install Zed."
    status=1
  }
  if (( status == 0 )); then
    log_success "Zed installed."
  else
    log_warning "Zed installation finished with warnings."
  fi
  return "${status}"
}

install_zmx_linux() {
  log_info "Installing zmx..."
  local arch zmx_arch latest tmp_dir zip_path
  arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
  case "${arch}" in
    amd64|x86_64) zmx_arch="x86_64" ;;
    arm64|aarch64) zmx_arch="aarch64" ;;
    *)
      log_warning "Unsupported architecture for zmx: ${arch}; skipping."
      return 1
      ;;
  esac

  # Tags straight from git: no API quota, and sorted by version
  latest=$(git ls-remote --tags --refs --sort=-v:refname https://github.com/neurosnap/zmx 2>/dev/null \
    | head -n1 | sed 's|.*refs/tags/||')
  if [[ -z "${latest}" ]]; then
    log_warning "Could not determine zmx version; skipping."
    return 1
  fi

  tmp_dir=$(mktemp -d)
  zip_path="${tmp_dir}/zmx.tar.gz"
  curl -fsSL "https://zmx.sh/a/zmx-${latest#v}-linux-${zmx_arch}.tar.gz" -o "${zip_path}" || {
    log_warning "Failed to download zmx."
    rm -rf "${tmp_dir}"
    return 1
  }

  tar -xzf "${zip_path}" -C "${tmp_dir}" || {
    log_warning "Failed to extract zmx."
    rm -rf "${tmp_dir}"
    return 1
  }

  sudo install -m 755 "${tmp_dir}/zmx" /usr/local/bin/zmx || {
    log_warning "Failed to install zmx binary."
    rm -rf "${tmp_dir}"
    return 1
  }

  rm -rf "${tmp_dir}"
  log_success "zmx installed."
}

install_ctop() {
  log_info "Installing ctop..."
  local arch latest tmp_dir binary_path
  arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
  case "${arch}" in
    amd64|x86_64) arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
    *)
      log_warning "Unsupported architecture for ctop: ${arch}; skipping."
      return 1
      ;;
  esac

  latest=$(github_latest_tag bcicen/ctop)
  if [[ -z "${latest}" ]]; then
    log_warning "Could not determine ctop version; skipping."
    return 1
  fi
  tmp_dir=$(mktemp -d)
  binary_path="${tmp_dir}/ctop"
  if ! curl -fsSL "https://github.com/bcicen/ctop/releases/download/${latest}/ctop-${latest#v}-linux-${arch}" -o "${binary_path}" \
    || ! sudo install -m 755 "${binary_path}" /usr/local/bin/ctop; then
    log_warning "ctop installation finished with warnings."
    rm -rf "${tmp_dir}"
    return 1
  fi

  rm -rf "${tmp_dir}"

  if [[ -x /usr/local/bin/ctop ]]; then
    log_success "ctop installed."
  else
    log_warning "ctop installation finished with warnings."
    return 1
  fi
}

# From the release tarball rather than getcroc.schollz.com, whose script
# queries the GitHub API and fails once the anonymous rate limit is hit
install_croc() {
  log_info "Installing croc..."
  local arch croc_arch latest tmp_dir
  arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
  case "${arch}" in
    amd64|x86_64) croc_arch="64bit" ;;
    arm64|aarch64) croc_arch="ARM64" ;;
    *)
      log_warning "Unsupported architecture for croc: ${arch}; skipping."
      return 1
      ;;
  esac

  latest=$(github_latest_tag schollz/croc)
  if [[ -z "${latest}" ]]; then
    log_warning "Could not determine croc version; skipping."
    return 1
  fi

  tmp_dir=$(mktemp -d)
  if ! curl_https "https://github.com/schollz/croc/releases/download/${latest}/croc_${latest}_Linux-${croc_arch}.tar.gz" \
      -o "${tmp_dir}/croc.tar.gz" \
    || ! tar -xzf "${tmp_dir}/croc.tar.gz" -C "${tmp_dir}" croc \
    || ! sudo install -m 755 "${tmp_dir}/croc" /usr/local/bin/croc; then
    log_warning "croc installation finished with warnings."
    rm -rf "${tmp_dir}"
    return 1
  fi
  rm -rf "${tmp_dir}"

  if command -v croc &>/dev/null; then
    log_success "croc installed."
  else
    log_warning "croc installation finished with warnings."
    return 1
  fi
}

install_yazi() {
  log_info "Installing yazi..."
  local arch deb_arch deb_url deb_file
  arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
  case "${arch}" in
    amd64|x86_64) deb_arch="x86_64-unknown-linux-gnu" ;;
    arm64|aarch64) deb_arch="aarch64-unknown-linux-gnu" ;;
    *)
      log_warning "Unsupported architecture for yazi: ${arch}; skipping."
      return 1
      ;;
  esac

  deb_url="https://github.com/sxyazi/yazi/releases/latest/download/yazi-${deb_arch}.deb"
  deb_file="${WORK_DIR}/yazi-${deb_arch}.deb"

  if ! curl -fsSL "${deb_url}" -o "${deb_file}" || ! apt_get install "${deb_file}"; then
    log_warning "yazi installation finished with warnings."
    rm -f "${deb_file}"
    return 1
  fi
  rm -f "${deb_file}"

  if command -v yazi &>/dev/null; then
    log_success "yazi installed."
  else
    log_warning "yazi installation finished with warnings."
    return 1
  fi
}

# =============================================================================
# SHARED FUNCTIONS
# =============================================================================

# Prints "name<TAB>url<TAB>git|file" for each manifest entry
zsh_plugin_entries() {
  local plugins_file="${DOTFILES_DIR}/home/.zsh_plugins.txt" line
  [[ -f "${plugins_file}" ]] || return 1

  while read -r line || [[ -n "$line" ]]; do
    # Remove leading/trailing whitespace and comments
    line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    local name url kind="git"
    if [[ "$line" =~ ^http ]]; then
      url="$line"
      local temp="${line#*://}"
      local domain="${temp%%/*}"
      local path_part="${temp#*/}"
      local domain_clean="${domain%.*}"
      local domain_hyphen="${domain_clean//./-}"
      local path_hyphen="${path_part//\//-}"
      if [[ "$path_part" != "$temp" ]]; then
        name="${domain_hyphen}-${path_hyphen}"
      else
        name="${domain_hyphen}"
      fi
      name="${name%.git}"
      if [[ "$url" != *".git"* && "$url" == *"iterm2.com"* ]]; then
        kind="file"
      fi
    else
      name=$(basename "$line")
      url="https://github.com/${line}"
    fi
    printf '%s\t%s\t%s\n' "${name}" "${url}" "${kind}"
  done < "${plugins_file}"
}

install_zsh_plugins() {
  local plugins_dir="${HOME}/.local/share/zsh/plugins"
  local failures=0 name url kind entries
  log_info "Installing zsh plugins..."
  mkdir -p "${plugins_dir}"

  if ! entries="$(zsh_plugin_entries)"; then
    log_error "Plugin manifest file not found: ${DOTFILES_DIR}/home/.zsh_plugins.txt"
    return 2
  fi

  while IFS=$'\t' read -r name url kind; do
    [[ -z "${name}" ]] && continue
    local target_dir="${plugins_dir}/${name}"
    if [[ "${kind}" == "git" ]]; then
      if [[ -d "${target_dir}/.git" ]]; then
        log_info "Updating ${name}..."
        git -C "${target_dir}" pull --ff-only || {
          log_warning "Failed to update ${name}."
          failures=$((failures + 1))
        }
      else
        log_info "Cloning ${name}..."
        git clone --depth=1 "${url}" "${target_dir}" || {
          log_warning "Failed to clone ${name}."
          failures=$((failures + 1))
        }
      fi
    else
      log_info "Downloading ${name}..."
      mkdir -p "${target_dir}"
      curl -fsSL "${url}" -o "${target_dir}/${name}.plugin.zsh" || {
        log_warning "Failed to download ${name}."
        failures=$((failures + 1))
      }
    fi
  done <<<"${entries}"

  if (( failures == 0 )); then
    log_success "Zsh plugins installed."
  else
    log_warning "Zsh plugin installation finished with ${failures} warning(s)."
  fi

  (( failures == 0 ))
}

font_dir() {
  case "${OS}" in
    Darwin) printf '%s' "${HOME}/Library/Fonts/Monaspace" ;;
    Linux)  printf '%s' "${XDG_DATA_HOME:-${HOME}/.local/share}/fonts/Monaspace" ;;
  esac
}

install_nerd_fonts() {
  log_info "Installing Monaspace Nerd Font..."
  local target_dir tmp_dir zip_path
  target_dir="$(font_dir)"

  mkdir -p "${target_dir}"
  tmp_dir=$(mktemp -d)
  zip_path="${tmp_dir}/Monaspace.zip"

  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Monaspace.zip" \
    -o "${zip_path}" || { log_warning "Failed to download Monaspace Nerd Font."; rm -rf "${tmp_dir}"; return 1; }
  unzip -o "${zip_path}" -d "${target_dir}" || {
    log_warning "Failed to extract Monaspace Nerd Font."
    rm -rf "${tmp_dir}"
    return 1
  }
  rm -rf "${tmp_dir}"

  if [[ "${OS}" == "Linux" ]]; then
    fc-cache -fv || {
      log_warning "Failed to refresh font cache."
      return 1
    }
  fi

  log_success "Monaspace Nerd Font installed."
}

backup_existing_dotfiles() {
  local backup_dir
  backup_dir="${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
  local found_any=0 rel_path target

  while IFS= read -r rel_path; do
    target="${HOME}/${rel_path}"
    if [[ -f "$target" && ! -L "$target" ]] && ! cmp -s "${DOTFILES_DIR}/home/${rel_path}" "$target"; then
      [[ "$found_any" -eq 0 ]] && { mkdir -p "$backup_dir"; found_any=1; }
      mkdir -p "$(dirname "${backup_dir}/${rel_path}")"
      cp -a "$target" "${backup_dir}/${rel_path}"
    fi
  done < <(dotfile_list)

  if (( found_any )); then
    log_info "Existing dotfiles backed up to ${backup_dir}"
  fi
}

deploy_dotfiles() {
  log_info "Deploying dotfiles..."
  local status=0

  if ! command -v rsync >/dev/null 2>&1; then
    log_error "rsync not found."
    return 2
  fi

  backup_existing_dotfiles

  mkdir -p "${HOME}/.config/zsh/functions"

  rsync -av --no-perms --exclude .DS_Store "${DOTFILES_DIR}/home/" "${HOME}/" || {
    log_error "Failed to rsync shared dotfiles."
    return 2
  }

  if (( status == 0 )); then
    log_success "Dotfiles deployed."
  else
    log_warning "Dotfile deployment finished with warnings."
  fi

  return "${status}"
}

configure_zsh() {
  log_info "Configuring zsh as default shell..."
  local status=0

  local zsh_path
  case "${OS}" in
    Darwin)
      zsh_path="$(brew --prefix)/bin/zsh"
      if [[ ! -f "${zsh_path}" ]]; then
        log_error "Homebrew zsh not found at ${zsh_path}"
        return 2
      fi
      ;;
    Linux)
      zsh_path="$(command -v zsh || true)"
      if [[ -z "${zsh_path}" ]]; then
        log_error "zsh not found."
        return 2
      fi
      ;;
  esac

  if ! grep -qxF "${zsh_path}" /etc/shells 2>/dev/null; then
    echo "${zsh_path}" | sudo tee -a /etc/shells >/dev/null || {
      log_error "Failed to add zsh to /etc/shells."
      return 2
    }
  fi

  if [[ "$(login_shell)" != "${zsh_path}" ]]; then
    sudo chsh -s "${zsh_path}" "${CURRENT_USER}" || {
      log_warning "Failed to change default shell. Run manually: chsh -s ${zsh_path}"
      status=1
    }
  fi

  if (( status == 0 )); then
    log_success "zsh configured as default shell."
  else
    log_warning "zsh configuration finished with warnings."
  fi

  return "${status}"
}

# =============================================================================
# DRY-RUN PLANS
# =============================================================================

# Each plan_<step> prints what that step would do, one line per call to plan.
plan() {
  local text="$*" plain color="" width line
  plain="$(printf '%s' "${text}" | strip_ansi)"
  term_size
  width=$(( COLS - 8 ))
  (( width > 90 )) && width=90
  if (( ${#plain} <= width )); then
    printf '      %s\n' "${text}"
    return
  fi
  # Long lines lose inner colors but keep the leading one on every line
  [[ "${text}" == $'\e'* ]] && color="${text%%m*}m"
  while IFS= read -r line; do
    printf '      %s%s%s\n' "${color}" "${line}" "${color:+${C_RESET}}"
  done < <(wrap "${plain}" "${width}")
}

plan_list() {
  local what="$1" total="$2"
  shift 2
  if (( $# == 0 )); then
    plan "${C_DIM}All ${total} ${what} already installed${C_RESET}"
  else
    plan "Would install $# of ${total} ${what}: $(join_by ", " "$@")"
  fi
}

brew_missing() {
  local kind="$1" installed="" pkg
  shift
  installed=$'\n'"$(brew list "--${kind}" -1 2>/dev/null)"$'\n'
  for pkg in "$@"; do
    [[ "${installed}" == *$'\n'"${pkg##*/}"$'\n'* ]] || printf '%s\n' "${pkg##*/}"
  done
}

plan_install_updates_macos() {
  plan "Would run softwareupdate for all available macOS updates"
  if command -v brew >/dev/null 2>&1; then
    local outdated
    outdated=$(HOMEBREW_NO_AUTO_UPDATE=1 brew outdated -q 2>/dev/null | grep -c . || true)
    plan "Would run brew update, upgrade (${outdated} outdated) and cleanup"
  fi
}

plan_install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    plan "${C_DIM}Already installed at $(brew --prefix)${C_RESET}"
  else
    plan "Would install Homebrew and add shellenv to ~/.zprofile"
  fi
}

plan_install_homebrew_packages() {
  local missing=()
  if ! command -v brew >/dev/null 2>&1; then
    plan "Would install ${#BREW_FORMULAE[@]} formulae and ${#BREW_CASKS[@]} casks once Homebrew is installed"
    return
  fi
  while IFS= read -r pkg; do [[ -n "${pkg}" ]] && missing+=("${pkg}"); done \
    < <(brew_missing formula "${BREW_FORMULAE[@]}")
  plan_list "core formulae" "${#BREW_FORMULAE[@]}" ${missing[@]+"${missing[@]}"}
  missing=()
  while IFS= read -r pkg; do [[ -n "${pkg}" ]] && missing+=("${pkg}"); done \
    < <(brew_missing cask "${BREW_CASKS[@]}")
  plan_list "core casks" "${#BREW_CASKS[@]}" ${missing[@]+"${missing[@]}"}

  if (( ${#SELECTED_FORMULAE_OPTIONAL[@]} + ${#SELECTED_CASKS_OPTIONAL[@]} > 0 )); then
    missing=()
    while IFS= read -r pkg; do [[ -n "${pkg}" ]] && missing+=("${pkg}"); done \
      < <(brew_missing formula ${SELECTED_FORMULAE_OPTIONAL[@]+"${SELECTED_FORMULAE_OPTIONAL[@]}"})
    while IFS= read -r pkg; do [[ -n "${pkg}" ]] && missing+=("${pkg}"); done \
      < <(brew_missing cask ${SELECTED_CASKS_OPTIONAL[@]+"${SELECTED_CASKS_OPTIONAL[@]}"})
    plan_list "selected optional packages" \
      $(( ${#SELECTED_FORMULAE_OPTIONAL[@]} + ${#SELECTED_CASKS_OPTIONAL[@]} )) \
      ${missing[@]+"${missing[@]}"}
  else
    plan "${C_DIM}No optional packages selected${C_RESET}"
  fi
}

plan_setup_icloud_links() {
  local icloud="${HOME}/Library/Mobile Documents/com~apple~CloudDocs"
  if [[ -L "${HOME}/iCloud" && "$(readlink "${HOME}/iCloud")" == "${icloud}" ]]; then
    plan "${C_DIM}~/iCloud already linked${C_RESET}"
  else
    plan "Would link ~/iCloud to iCloud Drive"
  fi
  if [[ ! -d "${icloud}/Downloads" ]]; then
    plan "${C_DIM}No iCloud Downloads folder; ~/Downloads left alone${C_RESET}"
  elif [[ -L "${HOME}/Downloads" ]]; then
    plan "${C_DIM}~/Downloads already a symlink${C_RESET}"
  elif (( REPLACE_DOWNLOADS )) || [[ -z "$(ls -A "${HOME}/Downloads" 2>/dev/null)" ]]; then
    plan "Would replace ~/Downloads with a link to iCloud Downloads"
  else
    plan "Would keep the non-empty ~/Downloads (not replaced)"
  fi
}

plan_setup_ghostty_config() {
  local link="${HOME}/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
  if [[ -L "${link}" && "$(readlink "${link}")" == "${HOME}/.config/ghostty/config.ghostty" ]]; then
    plan "${C_DIM}Already linked${C_RESET}"
  else
    plan "Would link Ghostty's config to ~/.config/ghostty/config.ghostty"
  fi
}

plan_install_updates_debian() {
  plan "Would modernize apt sources, then apt update, full-upgrade and autoremove"
}

plan_install_apt_packages() {
  local pkg missing=()
  for pkg in "${APT_PACKAGES[@]}"; do
    [[ "$(dpkg-query -W -f='${db:Status-Abbrev}' "${pkg}" 2>/dev/null)" == "ii "* ]] || missing+=("${pkg}")
  done
  plan_list "apt packages" "${#APT_PACKAGES[@]}" ${missing[@]+"${missing[@]}"}
}

plan_binary() {
  local name="$1" path
  if path="$(command -v "${name}" 2>/dev/null)"; then
    plan "${C_DIM}Installed at ${path}; would reinstall the latest release${C_RESET}"
  else
    plan "Would install the latest ${name} release"
  fi
}

plan_install_pfetch_rs() { plan_binary pfetch; }
plan_install_ghostty()   { plan_binary ghostty; }
plan_install_zed()       { plan_binary zed; }
plan_install_ctop()      { plan_binary ctop; }
plan_install_zmx_linux() { plan_binary zmx; }
plan_install_croc()      { plan_binary croc; }
plan_install_yazi()      { plan_binary yazi; }

plan_install_zsh_plugins() {
  local plugins_dir="${HOME}/.local/share/zsh/plugins" name url kind entries
  local clone=() update=() fetch=()
  if ! entries="$(zsh_plugin_entries)"; then
    plan "${C_RED}Plugin manifest not found${C_RESET}"
    return
  fi
  while IFS=$'\t' read -r name url kind; do
    [[ -z "${name}" ]] && continue
    if [[ "${kind}" == "file" ]]; then
      fetch+=("${name}")
    elif [[ -d "${plugins_dir}/${name}/.git" ]]; then
      update+=("${name}")
    else
      clone+=("${name}")
    fi
  done <<<"${entries}"
  (( ${#clone[@]} ))  && plan "Would clone: $(join_by ", " "${clone[@]}")"
  (( ${#update[@]} )) && plan "Would update ${#update[@]} existing plugins"
  (( ${#fetch[@]} ))  && plan "Would download: $(join_by ", " "${fetch[@]}")"
  return 0
}

plan_install_nerd_fonts() {
  local dir
  dir="$(font_dir)"
  if [[ -d "${dir}" && -n "$(ls -A "${dir}" 2>/dev/null)" ]]; then
    plan "${C_DIM}Already installed; would re-download the latest release${C_RESET}"
  else
    plan "Would download Monaspace Nerd Font to $(tildify "${dir}")"
  fi
}

plan_configure_zsh() {
  local current target
  current="$(login_shell)"
  target="$(target_zsh)"
  if [[ -z "${target}" ]]; then
    plan "Would set zsh as login shell once it is installed"
  elif [[ "${current}" == "${target}" ]]; then
    plan "${C_DIM}Login shell is already ${target}${C_RESET}"
  else
    plan "Would change login shell from ${current:-unknown} to ${target}"
  fi
}

plan_deploy_dotfiles() {
  local rel
  dotfile_changes
  if (( ${#DF_NEW[@]} + ${#DF_CHANGED[@]} == 0 )); then
    plan "${C_DIM}All ${DF_SAME} files already match${C_RESET}"
    return
  fi
  for rel in ${DF_CHANGED[@]+"${DF_CHANGED[@]}"}; do
    plan "${C_YELLOW}~${C_RESET} ~/${rel}  ${C_DIM}$(diff_counts "${rel}")${C_RESET}"
  done
  for rel in ${DF_NEW[@]+"${DF_NEW[@]}"}; do
    plan "${C_GREEN}+${C_RESET} ~/${rel}  ${C_DIM}new${C_RESET}"
  done
  (( DF_SAME )) && plan "${C_DIM}${DF_SAME} unchanged${C_RESET}"
  (( ${#DF_CHANGED[@]} )) && plan "${C_DIM}Changed files are backed up to ~/.dotfiles-backup first${C_RESET}"
  return 0
}

# =============================================================================
# STEPS
# =============================================================================

STEP_FNS=() STEP_LABELS=() STEP_DESCS=() STEP_SUDO=() STEP_FG=() STEP_ON=()

# add_step fn label description needs_sudo [foreground]
# Foreground steps run attached to the terminal because they can prompt.
add_step() {
  STEP_FNS+=("$1")
  STEP_LABELS+=("$2")
  STEP_DESCS+=("$3")
  STEP_SUDO+=("$4")
  STEP_FG+=("${5:-0}")
  STEP_ON+=(1)
}

define_steps() {
  case "${OS}" in
    Darwin)
      local brew_sudo=0
      command -v brew >/dev/null 2>&1 || brew_sudo=1
      # softwareupdate can ask for the volume owner's password on Apple Silicon
      add_step install_updates_macos     "System updates"      "softwareupdate, then brew upgrade"            1 1
      add_step install_homebrew          "Homebrew"            "Install Homebrew if it's missing"             "${brew_sudo}"
      add_step install_homebrew_packages "Packages"            "Core formulae and casks, plus optional picks" 1
      add_step install_zsh_plugins       "Zsh plugins"         "Clone or update plugins from .zsh_plugins.txt" 0
      add_step install_nerd_fonts        "Monaspace Nerd Font" "Download into ~/Library/Fonts"                0
      add_step configure_zsh             "Default shell"       "Make Homebrew zsh the login shell"            1
      add_step deploy_dotfiles           "Dotfiles"            "Back up changed files, then copy home/ to ~"  0
      # shellcheck disable=SC2088
      add_step setup_icloud_links        "iCloud links"        '~/iCloud and ~/Downloads into iCloud Drive'   0
      add_step setup_ghostty_config      "Ghostty config"      "Link config into Application Support"         0
      ;;
    Linux)
      add_step install_updates_debian "System updates"      "apt update and full-upgrade"                   1
      add_step install_apt_packages   "APT packages"        "CLI tools from the Debian archive"             1
      add_step install_pfetch_rs      "pfetch-rs"           "Latest release into /usr/local/bin"            1
      add_step install_zsh_plugins    "Zsh plugins"         "Clone or update plugins from .zsh_plugins.txt" 0
      add_step install_ghostty        "Ghostty"             "Terminal emulator .deb"                        1
      add_step install_zed            "Zed"                 "Zed Preview into ~/.local"                     0
      add_step install_ctop           "ctop"                "Container top, into /usr/local/bin"            1
      add_step install_zmx_linux      "zmx"                 "Session persistence, into /usr/local/bin"      1
      add_step install_croc           "croc"                "File transfer tool"                            1
      add_step install_yazi           "yazi"                "Terminal file manager .deb"                    1
      add_step install_nerd_fonts     "Monaspace Nerd Font" "Download into ~/.local/share/fonts"            0
      add_step deploy_dotfiles        "Dotfiles"            "Back up changed files, then copy home/ to ~"   0
      add_step configure_zsh          "Default shell"       "Make zsh the login shell"                      1
      ;;
  esac
}

step_selected() {
  local fn="$1" i
  for (( i = 0; i < ${#STEP_FNS[@]}; i++ )); do
    [[ "${STEP_FNS[i]}" == "${fn}" && "${STEP_ON[i]}" == "1" ]] && return 0
  done
  return 1
}

# =============================================================================
# PREFLIGHT
# =============================================================================

die() {
  screen_leave
  cursor_show
  printf '%s\n' "${C_RED}${C_BOLD}${G_FAIL}${C_RESET} $*" >&2
  exit 1
}

preflight() {
  case "${OS}" in
    Darwin)
      if [[ "$(uname -m)" != "arm64" ]]; then
        die "Apple Silicon (arm64) required. Detected: $(uname -m)"
      fi
      ;;
    Linux)
      if [[ -n "${SUDO_USER:-}" || "${EUID}" -eq 0 ]]; then
        die "Run this as your regular user, not root or sudo. It asks for sudo when it needs it."
      fi
      if ! command -v sudo >/dev/null 2>&1; then
        die "sudo is required. Install it and add ${CURRENT_USER} to the sudo group, then rerun."
      fi
      local id="" codename="" name="Linux"
      if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        id="$(. /etc/os-release && printf '%s' "${ID:-}")"
        codename="$(. /etc/os-release && printf '%s' "${VERSION_CODENAME:-}")"
        name="$(. /etc/os-release && printf '%s' "${NAME:-Linux}")"
      fi
      if [[ "${id}" != "debian" ]]; then
        PREFLIGHT_WARNING="This installer targets Debian. Many steps may not work on ${name}."
      elif [[ -n "${codename}" && "${codename}" != "trixie" ]]; then
        PREFLIGHT_NOTE="Tuned for Debian trixie; this is ${codename}."
      fi
      ;;
    *)
      die "Unsupported OS: ${OS}. This installer supports macOS and Debian."
      ;;
  esac
}

# =============================================================================
# WIZARD
# =============================================================================

downloads_needs_decision() {
  [[ "${OS}" == "Darwin" ]] || return 1
  step_selected setup_icloud_links || return 1
  [[ -d "${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Downloads" ]] || return 1
  [[ -d "${HOME}/Downloads" && ! -L "${HOME}/Downloads" ]] || return 1
  [[ -n "$(ls -A "${HOME}/Downloads" 2>/dev/null)" ]]
}

wizard_screens() {
  WIZARD_SCREENS=()
  [[ -n "${PREFLIGHT_WARNING:-}" ]] && WIZARD_SCREENS+=("System")
  WIZARD_SCREENS+=("Steps")
  step_selected install_homebrew_packages && WIZARD_SCREENS+=("Packages")
  downloads_needs_decision && WIZARD_SCREENS+=("Downloads")
  WIZARD_SCREENS+=("Review")
}

screen_system() {
  set_breadcrumb "System"
  ui_question "Continue on this system?" \
    "${C_YELLOW}${US}${PREFLIGHT_WARNING}"$'\n'"${US}"$'\n'"${US}Steps that rely on apt or Debian package names may fail." n
  case $? in
    0) return 0 ;;
    *) quit_wizard ;;
  esac
}

screen_steps() {
  local i selected
  CL_LABELS=("${STEP_LABELS[@]}")
  CL_DESCS=("${STEP_DESCS[@]}")
  CL_ON=("${STEP_ON[@]}")
  CL_TAGS=()
  for (( i = 0; i < ${#STEP_FNS[@]}; i++ )); do
    CL_TAGS+=("")
    (( STEP_SUDO[i] )) && CL_TAGS[i]="sudo"
  done
  CL_CUR=0 CL_TOP=0 CL_MSG="" CL_LIVE_STEPS=1
  set_breadcrumb "Steps"
  local subtitle="Pick what to run. Steps run top to bottom."
  [[ -n "${PREFLIGHT_NOTE:-}" ]] && subtitle+=" ${PREFLIGHT_NOTE}"

  while true; do
    ui_checklist "What should the installer do?" "${subtitle}"
    local rc=$?
    CL_LIVE_STEPS=0
    STEP_ON=("${CL_ON[@]}")
    (( rc == 1 )) && return 1
    selected=0
    for i in "${STEP_ON[@]}"; do [[ "${i}" == "1" ]] && selected=$(( selected + 1 ))
    done
    if (( selected == 0 )); then
      CL_MSG="Select at least one step, or press q to quit."
      continue
    fi
    return 0
  done
}

screen_packages() {
  local entry name installed_f installed_c have_brew=0
  command -v brew >/dev/null 2>&1 && have_brew=1
  installed_f="" installed_c=""
  if (( have_brew )); then
    installed_f=$'\n'"$(brew list --formula -1 2>/dev/null)"$'\n'
    installed_c=$'\n'"$(brew list --cask -1 2>/dev/null)"$'\n'
  fi

  CL_LABELS=("Formulae") CL_DESCS=("") CL_ON=("h") CL_TAGS=("")
  for entry in "${BREW_FORMULAE_OPTIONAL[@]}"; do
    name="${entry%%:*}"
    CL_LABELS+=("${name}")
    CL_DESCS+=("${entry#*:}")
    if (( ! PACKAGES_VISITED )) && [[ "${installed_f}" == *$'\n'"${name}"$'\n'* ]]; then
      CL_ON+=(1)
    elif in_list "${name}" ${SELECTED_FORMULAE_OPTIONAL[@]+"${SELECTED_FORMULAE_OPTIONAL[@]}"}; then
      CL_ON+=(1)
    else
      CL_ON+=(0)
    fi
    if [[ "${installed_f}" == *$'\n'"${name}"$'\n'* ]]; then CL_TAGS+=("installed"); else CL_TAGS+=(""); fi
  done
  CL_LABELS+=("Casks") CL_DESCS+=("") CL_ON+=("h") CL_TAGS+=("")
  for entry in "${BREW_CASKS_OPTIONAL[@]}"; do
    name="${entry%%:*}"
    CL_LABELS+=("${name}")
    CL_DESCS+=("${entry#*:}")
    if (( ! PACKAGES_VISITED )) && [[ "${installed_c}" == *$'\n'"${name}"$'\n'* ]]; then
      CL_ON+=(1)
    elif in_list "${name}" ${SELECTED_CASKS_OPTIONAL[@]+"${SELECTED_CASKS_OPTIONAL[@]}"}; then
      CL_ON+=(1)
    else
      CL_ON+=(0)
    fi
    if [[ "${installed_c}" == *$'\n'"${name}"$'\n'* ]]; then CL_TAGS+=("installed"); else CL_TAGS+=(""); fi
  done
  CL_CUR=0 CL_TOP=0 CL_MSG=""
  set_breadcrumb "Packages"

  ui_checklist "Optional packages" \
    "${#BREW_FORMULAE[@]} core formulae and ${#BREW_CASKS[@]} casks are always installed. Pick extras; ones you have start checked."
  local rc=$? i section=""
  PACKAGES_VISITED=1
  SELECTED_FORMULAE_OPTIONAL=()
  SELECTED_CASKS_OPTIONAL=()
  for (( i = 0; i < ${#CL_LABELS[@]}; i++ )); do
    if [[ "${CL_ON[i]}" == "h" ]]; then
      section="${CL_LABELS[i]}"
    elif [[ "${CL_ON[i]}" == "1" ]]; then
      if [[ "${section}" == "Formulae" ]]; then
        SELECTED_FORMULAE_OPTIONAL+=("${CL_LABELS[i]}")
      else
        SELECTED_CASKS_OPTIONAL+=("${CL_LABELS[i]}")
      fi
    fi
  done
  return "${rc}"
}

screen_downloads() {
  local count
  count=$(find "${HOME}/Downloads" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
  set_breadcrumb "Downloads"
  local default="n"
  (( REPLACE_DOWNLOADS )) && default="y"
  # shellcheck disable=SC2088
  ui_question "Replace ~/Downloads?" \
    "${US}~/Downloads is a regular folder with ${count} items. The iCloud links step can delete it and link iCloud Drive's Downloads there instead."$'\n'"${US}"$'\n'"${C_RED}${US}Choosing yes permanently deletes what's in ~/Downloads now."$'\n'"${US}Choosing no still links ~/iCloud and leaves ~/Downloads alone." \
    "${default}"
  case $? in
    0) REPLACE_DOWNLOADS=1; return 0 ;;
    1) REPLACE_DOWNLOADS=0; return 0 ;;
    *) return 1 ;;
  esac
}

needs_sudo() {
  local i
  (( DRY_RUN )) && return 1
  for (( i = 0; i < ${#STEP_FNS[@]}; i++ )); do
    [[ "${STEP_ON[i]}" == "1" && "${STEP_SUDO[i]}" == "1" ]] && return 0
  done
  return 1
}

screen_review() {
  local i rel last_size="" max_files action
  dotfile_changes
  set_breadcrumb "Review"
  action="install"
  (( DRY_RUN )) && action="preview"
  KEY=""

  while true; do
    term_size
    if [[ "${KEY}" != "tick" || "${ROWS}x${COLS}" != "${last_size}" ]]; then
      last_size="${ROWS}x${COLS}"
      if too_small; then
        read_key
        [[ "${KEY}" == "quit" ]] && quit_wizard
        continue
      fi
      if (( DRY_RUN )); then
        frame_header "Ready to preview" "Dry run: each step reports what it would change. Nothing is modified."
      else
        frame_header "Ready to install" "Review the plan, then press enter to start."
      fi
      BODY=() BODY_MODE=1

      local on=() off=() wrapped
      for (( i = 0; i < ${#STEP_FNS[@]}; i++ )); do
        if [[ "${STEP_ON[i]}" == "1" ]]; then on+=("${STEP_LABELS[i]}"); else off+=("${STEP_LABELS[i]}"); fi
      done
      fl "  ${C_BOLD}Steps${C_RESET}  ${C_DIM}${#on[@]} of ${#STEP_FNS[@]}${C_RESET}"
      while IFS= read -r wrapped; do
        fl "    ${wrapped}"
      done < <(wrap "$(join_by ", " "${on[@]}")" "$(text_width 6)")
      if (( ${#off[@]} )); then
        while IFS= read -r wrapped; do
          fl "    ${C_DIM}${wrapped}${C_RESET}"
        done < <(wrap "Skipping $(join_by ", " "${off[@]}")" "$(text_width 6)")
      fi

      if step_selected install_homebrew_packages; then
        fl ""
        local picks=(${SELECTED_FORMULAE_OPTIONAL[@]+"${SELECTED_FORMULAE_OPTIONAL[@]}"} ${SELECTED_CASKS_OPTIONAL[@]+"${SELECTED_CASKS_OPTIONAL[@]}"})
        if (( ${#picks[@]} )); then
          fl "  ${C_BOLD}Optional packages${C_RESET}  ${C_DIM}$(fit "$(join_by ", " "${picks[@]}")" "$(text_width 23)")${C_RESET}"
        else
          fl "  ${C_BOLD}Optional packages${C_RESET}  ${C_DIM}none${C_RESET}"
        fi
      fi

      if downloads_needs_decision; then
        fl ""
        if (( REPLACE_DOWNLOADS )); then
          fl "  ${C_BOLD}~/Downloads${C_RESET}  ${C_RED}will be deleted and linked to iCloud${C_RESET}"
        else
          fl "  ${C_BOLD}~/Downloads${C_RESET}  ${C_DIM}kept as is${C_RESET}"
        fi
      fi

      if step_selected deploy_dotfiles; then
        fl ""
        if (( ${#DF_NEW[@]} + ${#DF_CHANGED[@]} == 0 )); then
          fl "  ${C_BOLD}Dotfiles${C_RESET}  ${C_DIM}all ${DF_SAME} files already match${C_RESET}"
        else
          local counts=()
          (( ${#DF_CHANGED[@]} )) && counts+=("${#DF_CHANGED[@]} changed")
          (( ${#DF_NEW[@]} )) && counts+=("${#DF_NEW[@]} new")
          (( DF_SAME )) && counts+=("${DF_SAME} unchanged")
          fl "  ${C_BOLD}Dotfiles${C_RESET}  ${C_DIM}$(join_by " ${G_DOT} " "${counts[@]}")${C_RESET}"
          max_files=8
          local shown=0 more=0
          for rel in ${DF_CHANGED[@]+"${DF_CHANGED[@]}"}; do
            if (( shown < max_files )); then
              # shellcheck disable=SC2088
              fl "    ${C_YELLOW}~${C_RESET} $(fit "~/${rel}" $(( COLS - 20 )))  ${C_DIM}$(diff_counts "${rel}")${C_RESET}"
              shown=$(( shown + 1 ))
            else
              more=$(( more + 1 ))
            fi
          done
          for rel in ${DF_NEW[@]+"${DF_NEW[@]}"}; do
            if (( shown < max_files )); then
              # shellcheck disable=SC2088
              fl "    ${C_GREEN}+${C_RESET} $(fit "~/${rel}" $(( COLS - 14 )))  ${C_DIM}new${C_RESET}"
              shown=$(( shown + 1 ))
            else
              more=$(( more + 1 ))
            fi
          done
          (( more )) && fl "    ${C_DIM}and ${more} more${C_RESET}"
          if (( ${#DF_CHANGED[@]} )); then
            fl "    ${C_DIM}Changed files are backed up to ~/.dotfiles-backup first.${C_RESET}"
          fi
        fi
      fi

      if needs_sudo; then
        fl ""
        fl "  ${C_DIM}Your password is needed once for steps marked sudo.${C_RESET}"
      fi

      FOOTER_MSG=""
      if step_selected deploy_dotfiles && (( ${#DF_NEW[@]} + ${#DF_CHANGED[@]} > 0 )); then
        set_hints "enter ${action}" "d view dotfile diff"
      else
        set_hints "enter ${action}"
      fi
      flush_body
      frame_footer
    fi

    read_key
    case "${KEY}" in
      enter) return 0 ;;
      back)  return 1 ;;
      quit)  quit_wizard ;;
      diff)
        if step_selected deploy_dotfiles && (( ${#DF_NEW[@]} + ${#DF_CHANGED[@]} > 0 )); then
          screen_leave
          cursor_show
          show_dotfile_diff
          screen_enter
          KEY=""
        fi
        ;;
    esac
  done
}

run_wizard() {
  local idx=0 screen
  screen_enter
  while true; do
    wizard_screens
    (( idx < 0 )) && idx=0
    (( idx >= ${#WIZARD_SCREENS[@]} )) && break
    screen="${WIZARD_SCREENS[idx]}"
    CAN_GO_BACK=0
    (( idx > 0 )) && CAN_GO_BACK=1
    if "screen_$(printf '%s' "${screen}" | tr '[:upper:]' '[:lower:]')"; then
      idx=$(( idx + 1 ))
    else
      idx=$(( idx - 1 ))
    fi
  done
  screen_leave
  cursor_show
}

# =============================================================================
# EXECUTION
# =============================================================================

STEP_STATUS=() STEP_TIME=()
STEP_PID=""
FG_RUNNING=0
SUDO_KEEPALIVE_PID=""
CANCELLED=0
STTY_SAVED=""
LABEL_WIDTH=0

print_banner() {
  local badge=""
  (( DRY_RUN )) && badge="  ${C_YELLOW}${C_BOLD}DRY RUN${C_RESET}"
  echo
  echo "  ${C_BOLD}${C_MAGENTA}dotfiles${C_RESET}  ${C_DIM}${SYS_INFO}${C_RESET}${badge}"
  term_size
  echo "  ${C_DIM}$(rule)${C_RESET}"
}

sudo_prime() {
  local labels=() i
  for (( i = 0; i < ${#STEP_FNS[@]}; i++ )); do
    [[ "${STEP_ON[i]}" == "1" && "${STEP_SUDO[i]}" == "1" ]] && labels+=("${STEP_LABELS[i]}")
  done
  echo
  echo "  ${C_BOLD}Administrator access${C_RESET}"
  term_size
  local line
  while IFS= read -r line; do
    echo "  ${C_DIM}${line}${C_RESET}"
  done < <(wrap "Needed for $(join_by ", " "${labels[@]}")." "$(text_width)")
  if ! sudo -n true 2>/dev/null; then
    if ! sudo -v -p "  Password for %u: "; then
      echo
      die "Could not get administrator access."
    fi
  fi

  # Steps run in their own process group; make sure the cached credential
  # reaches them, which fails when there's no controlling terminal
  local probe
  set -m
  ( sudo -n true ) </dev/null >/dev/null 2>&1 &
  probe=$!
  set +m
  if ! wait "${probe}"; then
    die "sudo won't reuse your password for background steps. Run the installer directly in a terminal, not through su or a pipe."
  fi
  echo "  ${C_GREEN}${G_OK}${C_RESET} ${C_DIM}Authenticated${C_RESET}"

  # Refresh the sudo timestamp so long steps don't hit a hidden prompt
  (
    while kill -0 "$$" 2>/dev/null; do
      sudo -n true 2>/dev/null
      sleep 30
    done
  ) >/dev/null 2>&1 &
  SUDO_KEEPALIVE_PID=$!
}

# Last non-empty line of the log, for the live preview under the spinner
log_tail_line() {
  tail -c 4000 "${LOG_FILE}" 2>/dev/null | tr '\r' '\n' | strip_ansi \
    | awk 'NF { line = $0 } END { print line }' | sed 's/^[[:space:]]*//'
}

kill_step() {
  [[ -n "${STEP_PID}" ]] || return 0
  kill -TERM -- "-${STEP_PID}" 2>/dev/null || kill -TERM "${STEP_PID}" 2>/dev/null
  wait "${STEP_PID}" 2>/dev/null
  STEP_PID=""
}

# $1 is the exit code to use: 130 for INT, 143 for TERM, 129 for HUP
on_interrupt() {
  local code="${1:-130}"
  if [[ -n "${STEP_PID}" ]]; then
    CANCELLED=1
    kill_step
    return
  fi
  if (( FG_RUNNING )); then
    # The foreground step shares our process group and got the signal too
    CANCELLED=1
    return
  fi
  if (( SCREEN_ALT )); then
    quit_wizard
  fi
  cursor_show
  echo
  echo "Cancelled."
  exit "${code}"
}

on_exit() {
  screen_leave
  cursor_show
  [[ -n "${STTY_SAVED}" ]] && stty "${STTY_SAVED}" </dev/tty 2>/dev/null
  [[ -n "${SUDO_KEEPALIVE_PID}" ]] && kill "${SUDO_KEEPALIVE_PID}" 2>/dev/null
  [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]] && rm -rf "${WORK_DIR}"
  return 0
}

# Environment every step runs with
step_env() {
  trap - INT TERM HUP EXIT
  export TMPDIR="${WORK_DIR}"
  export HOMEBREW_NO_ENV_HINTS=1
  # Some vendor installers (Zed's) read $SHELL, which docker exec and cron leave unset
  export SHELL="${SHELL:-$(login_shell)}"
  # Anything that asks sudo for a password gets a failing askpass instead of
  # a prompt nobody can see
  export SUDO_ASKPASS=/usr/bin/false
  # Same for git: a clone that needs credentials fails instead of stopping
  # on a read from the terminal
  export GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=/usr/bin/false
}

# Runs one step in its own process group so Ctrl-C can stop it cleanly, and
# shows a spinner with the step's latest output until it finishes.
run_one_step() {
  local i="$1"
  local fn="${STEP_FNS[i]}" label="${STEP_LABELS[i]}"
  local start frame=0 elapsed tail_line="" code width

  printf '\n===== %s (%s) =====\n' "${label}" "${fn}" >>"${LOG_FILE}"
  start="${SECONDS}"

  if (( STEP_FG[i] )); then
    run_fg_step "${i}"
    return
  fi

  set -m
  (
    step_env
    # Fail instead of hanging on a hidden password prompt
    # shellcheck disable=SC2329
    sudo() { command sudo -n "$@"; }
    "${fn}"
  ) </dev/null >>"${LOG_FILE}" 2>&1 &
  STEP_PID=$!
  set +m

  if (( TTY )); then
    cursor_hide
    printf '  %s %s\n\e[K' "${C_CYAN}${SPIN[0]}${C_RESET}" "${label}"
    while kill -0 "${STEP_PID}" 2>/dev/null; do
      if (( frame % 4 == 0 )); then
        tail_line="$(log_tail_line)"
        term_size
      fi
      width=$(( COLS - 8 ))
      (( width < 10 )) && width=10
      tail_line="$(fit "${tail_line}" "${width}")"
      elapsed="$(format_duration $(( SECONDS - start )))"
      printf '\r\e[1A  %s %-*s  %s\e[K\n    %s\e[K' \
        "${C_CYAN}${SPIN[frame % ${#SPIN[@]}]}${C_RESET}" "${LABEL_WIDTH}" "${label}" \
        "${C_DIM}${elapsed}${C_RESET}" "${C_DIM}${tail_line}${C_RESET}"
      frame=$(( frame + 1 ))
      sleep 0.12
    done
    printf '\r\e[K\e[1A'
  else
    printf '  %s ...\n' "${label}"
  fi

  if [[ -n "${STEP_PID}" ]]; then
    wait "${STEP_PID}"
    code=$?
  else
    code=130
  fi
  STEP_PID=""
  finish_step "${i}" "${code}" "${start}"
}

# Runs a step attached to the terminal, between a header and its result line
run_fg_step() {
  local i="$1" code start="${SECONDS}"
  echo "  ${C_CYAN}${G_BULLET}${C_RESET} ${STEP_LABELS[i]}  ${C_DIM}runs in the foreground and may ask for input${C_RESET}"
  echo "(ran in the foreground; output went to the terminal)" >>"${LOG_FILE}"
  cursor_show
  FG_RUNNING=1
  (
    step_env
    "${STEP_FNS[i]}"
  )
  code=$?
  FG_RUNNING=0
  echo
  finish_step "${i}" "${code}" "${start}"
}

finish_step() {
  local i="$1" code="$2" start="$3"
  load_brew_env

  STEP_TIME[i]=$(( SECONDS - start ))
  if (( CANCELLED )); then
    STEP_STATUS[i]="cancel"
  elif (( code == 0 )); then
    STEP_STATUS[i]="ok"
  elif (( code == 1 )); then
    STEP_STATUS[i]="warn"
  else
    STEP_STATUS[i]="fail"
  fi
  print_step_result "${i}"
}

print_step_result() {
  local i="$1"
  local icon note="" status="${STEP_STATUS[i]}"
  case "${status}" in
    ok)     icon="${C_GREEN}${G_OK}${C_RESET}" ;;
    warn)   icon="${C_YELLOW}${G_WARN}${C_RESET}"; note="${C_YELLOW}finished with warnings${C_RESET}" ;;
    fail)   icon="${C_RED}${G_FAIL}${C_RESET}"; note="${C_RED}failed${C_RESET}" ;;
    cancel) icon="${C_RED}${G_FAIL}${C_RESET}"; note="${C_RED}cancelled${C_RESET}" ;;
  esac
  local line
  line="$(printf '  %s %-*s  %s' "${icon}" "${LABEL_WIDTH}" "${STEP_LABELS[i]}" "${C_DIM}$(format_duration "${STEP_TIME[i]}")${C_RESET}")"
  [[ -n "${note}" ]] && line+="  ${note}"
  printf '\r%s\e[K\n' "${line}"

  if [[ "${status}" == "warn" || "${status}" == "fail" ]]; then
    step_log_excerpt "${STEP_FNS[i]}" "$([[ "${status}" == "fail" ]] && echo 8 || echo 3)"
  fi
}

# Last lines of one step's section of the log, preferring warnings and errors
step_log_excerpt() {
  local fn="$1" count="$2" section lines
  section="$(awk -v fn="(${fn})" '
    /^===== / { on = (index($0, fn) > 0) ; next }
    on' "${LOG_FILE}" | tr '\r' '\n' | strip_ansi | grep -v '^[[:space:]]*$')"
  lines="$(printf '%s\n' "${section}" \
    | grep -iE 'error|fail|fatal|denied|not found|not set|missing|unable|cannot|warning' \
    | grep -vE '^(INFO|SUCCESS):|finished with' | tail -n "${count}")"
  [[ -z "${lines}" ]] && lines="$(printf '%s\n' "${section}" | tail -n "${count}")"
  term_size
  while IFS= read -r l; do
    l="${l#ERROR:   }"
    l="${l#WARNING: }"
    [[ -z "${l}" ]] && continue
    (( ${#l} > COLS - 8 )) && l="${l:0:$(( COLS - 11 ))}..."
    printf '    %s\n' "${C_DIM}${l}${C_RESET}"
  done <<<"${lines}"
}

run_steps() {
  local i failed=0
  echo
  if (( DRY_RUN )); then
    echo "  ${C_BOLD}Preview${C_RESET}"
  else
    echo "  ${C_BOLD}Installing${C_RESET}"
  fi

  for (( i = 0; i < ${#STEP_FNS[@]}; i++ )); do
    STEP_STATUS[i]="skip"
    STEP_TIME[i]=0
    if [[ "${STEP_ON[i]}" == "1" ]] && (( ${#STEP_LABELS[i]} > LABEL_WIDTH )); then
      LABEL_WIDTH="${#STEP_LABELS[i]}"
    fi
  done

  for (( i = 0; i < ${#STEP_FNS[@]}; i++ )); do
    [[ "${STEP_ON[i]}" == "1" ]] || continue
    if (( failed || CANCELLED )); then
      STEP_STATUS[i]="blocked"
      continue
    fi
    if (( DRY_RUN )); then
      echo
      echo "  ${C_CYAN}${G_BULLET}${C_RESET} ${C_BOLD}${STEP_LABELS[i]}${C_RESET}"
      if declare -F "plan_${STEP_FNS[i]}" >/dev/null; then
        "plan_${STEP_FNS[i]}"
      else
        plan "${STEP_DESCS[i]}"
      fi
      STEP_STATUS[i]="ok"
      continue
    fi
    run_one_step "${i}"
    [[ "${STEP_STATUS[i]}" == "fail" ]] && failed=1
  done
  cursor_show
}

print_summary() {
  local i ok=0 warn=0 fail=0 cancel=0 skipped=0 total_time=0 restart=0
  for (( i = 0; i < ${#STEP_FNS[@]}; i++ )); do
    case "${STEP_STATUS[i]}" in
      ok)          ok=$(( ok + 1 )) ;;
      warn)        warn=$(( warn + 1 )) ;;
      fail)        fail=$(( fail + 1 )) ;;
      cancel)      cancel=$(( cancel + 1 )) ;;
      *)           skipped=$(( skipped + 1 )) ;;
    esac
    total_time=$(( total_time + STEP_TIME[i] ))
    if [[ "${STEP_STATUS[i]}" == "ok" || "${STEP_STATUS[i]}" == "warn" ]]; then
      case "${STEP_FNS[i]}" in deploy_dotfiles|configure_zsh|install_zsh_plugins) restart=1 ;; esac
    fi
  done

  echo
  if (( DRY_RUN )); then
    echo "  ${C_YELLOW}${C_BOLD}Dry run complete.${C_RESET} Nothing was changed."
    echo "  ${C_DIM}Run without --dry-run to apply.${C_RESET}"
    echo
    return 0
  fi

  local blocked=()
  for (( i = 0; i < ${#STEP_FNS[@]}; i++ )); do
    [[ "${STEP_STATUS[i]}" == "blocked" ]] && blocked+=("${STEP_LABELS[i]}")
  done

  local parts=("${C_GREEN}${ok} done${C_RESET}")
  (( warn || fail || cancel )) || parts=("${C_DIM}${ok} step$( (( ok == 1 )) || echo s)${C_RESET}")
  (( warn )) && parts+=("${C_YELLOW}${warn} with warnings${C_RESET}")
  (( fail )) && parts+=("${C_RED}${fail} failed${C_RESET}")
  (( cancel )) && parts+=("${C_RED}${cancel} cancelled${C_RESET}")
  if (( CANCELLED )); then
    echo "  ${C_RED}${C_BOLD}Cancelled${C_RESET} after $(format_duration "${total_time}")  $(join_by " ${C_DIM}${G_DOT}${C_RESET} " "${parts[@]}")"
  elif (( fail )); then
    echo "  ${C_RED}${C_BOLD}Stopped${C_RESET} after $(format_duration "${total_time}")  $(join_by " ${C_DIM}${G_DOT}${C_RESET} " "${parts[@]}")"
  elif (( warn )); then
    echo "  ${C_YELLOW}${C_BOLD}Finished with warnings${C_RESET} in $(format_duration "${total_time}")  $(join_by " ${C_DIM}${G_DOT}${C_RESET} " "${parts[@]}")"
  else
    echo "  ${C_GREEN}${C_BOLD}All done${C_RESET} in $(format_duration "${total_time}")  $(join_by " ${C_DIM}${G_DOT}${C_RESET} " "${parts[@]}")"
  fi
  (( ${#blocked[@]} )) && echo "  ${C_DIM}Not run: $(join_by ", " "${blocked[@]}")${C_RESET}"
  if (( CANCELLED )) && [[ "${OS}" == "Linux" ]]; then
    echo "  ${C_YELLOW}If apt was interrupted, run: sudo dpkg --configure -a${C_RESET}"
  fi
  echo "  ${C_DIM}Full log: $(tildify "${LOG_FILE}")${C_RESET}"
  if (( restart && ! fail && ! CANCELLED )); then
    echo
    echo "  Open a new terminal to start using the updated shell."
  fi
  echo
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
  ui_init
  trap on_exit EXIT
  trap 'on_interrupt 130' INT
  trap 'on_interrupt 143' TERM
  trap 'on_interrupt 129' HUP

  if (( ! TTY && ! ASSUME_YES && ! DRY_RUN )); then
    if [[ -t 0 && -t 1 ]]; then
      echo "This terminal (TERM=${TERM:-unset}) can't show the interactive installer. Pass --yes to accept the defaults." >&2
    else
      echo "No terminal detected. Run this from a terminal, or pass --yes to accept the defaults." >&2
    fi
    exit 1
  fi

  (( TTY )) && STTY_SAVED="$(stty -g </dev/tty 2>/dev/null)"
  WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles.XXXXXX")" || {
    echo "Could not create a temporary directory." >&2
    exit 1
  }
  load_brew_env
  system_info
  PREFLIGHT_WARNING="" PREFLIGHT_NOTE=""
  preflight
  define_steps

  if (( INTERACTIVE )); then
    run_wizard
  elif [[ -n "${PREFLIGHT_WARNING}" ]]; then
    echo "${C_YELLOW}${G_WARN}${C_RESET} ${PREFLIGHT_WARNING} Continuing because of --yes." >&2
  fi

  print_banner
  if (( ! DRY_RUN )); then
    if ! mkdir -p "${LOG_DIR}" 2>/dev/null || ! : 2>/dev/null >"${LOG_FILE}"; then
      die "Could not create the log in $(tildify "${LOG_DIR}"). Check that it's writable."
    fi
  fi
  needs_sudo && sudo_prime
  run_steps
  print_summary

  if (( CANCELLED )); then
    # Die by SIGINT so a calling shell or script knows we were interrupted
    on_exit
    trap - EXIT INT
    kill -INT "$$"
  fi
  local i
  for (( i = 0; i < ${#STEP_FNS[@]}; i++ )); do
    [[ "${STEP_STATUS[i]}" == "fail" ]] && return 1
  done
  return 0
}

main "$@"

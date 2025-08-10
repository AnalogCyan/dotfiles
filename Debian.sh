#!/usr/bin/env bash
# =============================================================================
#
#  Dotfiles Installer Script for Debian (Trixie)
#
#  Author: AnalogCyan
#  License: Unlicense
#
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# USAGE
# =============================================================================

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  -h, --help    Show this help message and exit

This script installs dotfiles and configures a Debian (Trixie) environment.
EOF
}

while [[ "${#}" -gt 0 ]]; do
  case "${1}" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option: ${1}"
      usage
      exit 1
      ;;
  esac
done

# =============================================================================
# CONFIGURATION
# =============================================================================

# Debian package list (rough equivalents to the macOS Homebrew list)
# Notes on package names that differ from macOS:
# - fortune -> fortune-mod
# - xz      -> xz-utils
# - transmission -> transmission-gtk (desktop) or transmission-daemon (headless)
declare -a APT_PACKAGES=(
  antidote          # via git install below (kept here for documentation)
  bat
  btop
  fortune-mod
  fzf
  lazygit
  starship
  thefuck
  xz-utils
  yt-dlp
  zoxide
  zsh
  eza
  git
  curl
  ca-certificates
)

# Optional desktop apps (uncomment/adjust as desired)
# declare -a APT_DESKTOP_APPS=(
#   transmission-gtk
# )

# Git configuration
GIT_USER_NAME="AnalogCyan"
GIT_USER_EMAIL="git@thayn.me"

# Paths
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}INFO:${NC}    $*"; }
log_success() { echo -e "${GREEN}SUCCESS:${NC} $*"; }
log_warning() { echo -e "${YELLOW}WARNING:${NC} $*"; }
log_error()   { echo -e "${RED}ERROR:${NC}   $*"; }

confirm() {
  local prompt="${1:-Continue?} (y/n) "
  read -r -p "${prompt}" REPLY
  case "${REPLY}" in
    [yY]*) return 0 ;;
    *)     return 1 ;;
  esac
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    log_error "Required command not found: $1"
    exit 1
  }
}

# =============================================================================
# SYSTEM CHECKS
# =============================================================================

check_system_compatibility() {
  require_cmd awk
  require_cmd grep
  require_cmd sudo

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    local name="${NAME:-Unknown}"
    local id="${ID:-unknown}"
    local version_codename="${VERSION_CODENAME:-}"
    log_info "Detected OS: ${name} (${id}) codename=${version_codename}"

    if [[ "${id}" != "debian" ]]; then
      log_warning "This script targets Debian. Proceeding anyway (you may be on a derivative)."
    fi

    if [[ -n "${version_codename}" && "${version_codename}" != "trixie" ]]; then
      log_warning "This script is tuned for Debian 'trixie', but you are on '${version_codename}'. Continuing."
    fi
  else
    log_warning "/etc/os-release not found; proceeding blindly."
  fi

  if [[ "${EUID}" -eq 0 ]]; then
    log_warning "Running as root is not recommended. Continuing, but prefer using sudo."
  fi
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

install_updates() {
  log_info "Ensuring system is up-to-date (apt)..."
  sudo apt-get update -y || { log_warning "apt update failed"; }
  sudo apt-get -y full-upgrade || { log_warning "apt full-upgrade had issues"; }
  sudo apt-get -y autoremove || true
  sudo apt-get -y autoclean || true
  log_success "System update process completed."
}

install_apt_packages() {
  log_info "Installing core packages via apt..."
  # Filter out placeholders like 'antidote' which we'll install via git
  local pkgs=()
  for p in "${APT_PACKAGES[@]}"; do
    [[ "$p" == "antidote" ]] && continue
    pkgs+=("$p")
  done

  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends "${pkgs[@]}" || {
    log_warning "Some apt packages failed to install."
  }

  # If you want optional desktop apps, uncomment APT_DESKTOP_APPS above
  if [[ "${#APT_DESKTOP_APPS[@]:-0}" -gt 0 ]]; then
    log_info "Installing optional desktop apps..."
    sudo apt-get install -y --no-install-recommends "${APT_DESKTOP_APPS[@]}" || {
      log_warning "Some optional desktop apps failed to install."
    }
  fi

  log_success "apt package installation completed."
}

install_antidote() {
  # Antidote isn't in Debian repos; install/update from git
  local target="${HOME}/.antidote"
  if [[ -d "${target}/.git" ]]; then
    log_info "Updating Antidote (zsh plugin manager)..."
    git -C "${target}" pull --ff-only || log_warning "Failed to update Antidote."
  else
    log_info "Installing Antidote (zsh plugin manager)..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "${target}" || {
      log_warning "Failed to clone Antidote."
    }
  fi
}

install_binary_scripts() {
  log_info "Installing binary scripts and utilities..."

  mkdir -pv "${HOME}/bin/apps/pfetch/" || {
    log_error "Failed to create bin directories."
    return 1
  }

  # Copy bin scripts if present
  if [[ -d "${DOTFILES_DIR}/Nix/bin" ]]; then
    log_info "Copying bin scripts from dotfiles..."
    # shellcheck disable=SC2045
    for f in $(ls -1 "${DOTFILES_DIR}/Nix/bin" 2>/dev/null || true); do
      cp -f "${DOTFILES_DIR}/Nix/bin/${f}" "${HOME}/bin/" || log_warning "Failed to copy ${f}"
    done
  else
    log_warning "Bin scripts directory not found at ${DOTFILES_DIR}/Nix/bin"
  fi

  # Install/update pfetch
  log_info "Installing pfetch..."
  if [[ ! -d "${HOME}/bin/apps/pfetch/.git" ]]; then
    git clone https://github.com/dylanaraps/pfetch.git "${HOME}/bin/apps/pfetch/" || {
      log_warning "Failed to clone pfetch repository."
    }
  else
    (cd "${HOME}/bin/apps/pfetch" && git pull --ff-only) || {
      log_warning "Failed to update pfetch."
    }
  fi

  # Make sure scripts are executable
  find "${HOME}/bin" -type f -exec chmod +x {} \; 2>/dev/null || true

  log_success "Binary scripts and utilities installed."
}

install_config_files() {
  log_info "Installing configuration files..."

  mkdir -pv "${HOME}/.config/zsh/functions" "${HOME}/.zsh.d" || {
    log_warning "Failed to create zsh directories."
  }

  # Backup existing zshrc if it exists
  if [[ -f "${HOME}/.zshrc" ]]; then
    log_info "Backing up existing .zshrc to .zshrc.dotbak"
    mv -f "${HOME}/.zshrc" "${HOME}/.zshrc.dotbak" || log_warning "Failed to backup .zshrc."
  fi

  # Copy .zshrc from repo if available; otherwise create a minimal one
  if [[ -f "${DOTFILES_DIR}/Nix/.zshrc" ]]; then
    cp -f "${DOTFILES_DIR}/Nix/.zshrc" "${HOME}/.zshrc" || {
      log_warning "Failed to copy .zshrc; generating a minimal one."
    }
  fi

  if [[ ! -f "${HOME}/.zshrc" ]]; then
    log_info "Creating a minimal .zshrc for Debian..."
    cat >"${HOME}/.zshrc" <<'EOF'
# =============================================================================
#  Core Configuration (Debian)
# =============================================================================
export PATH="$HOME/bin:/usr/local/bin:$PATH"
export EDITOR='vim'

# Completion
autoload -Uz compinit
compinit -d ~/.zcompdump

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt histignorealldups
setopt histignorespace

# Antidote plugin manager
source "$HOME/.antidote/antidote.zsh" 2>/dev/null
antidote load ~/.zsh_plugins.txt 2>/dev/null

# Completion styles
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Tools
eval "$(thefuck --alias 2>/dev/null)"
eval "$(zoxide init zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(starship init zsh)"
EOF
  fi

  # Plugins file
  if [[ -f "${DOTFILES_DIR}/Nix/.zsh_plugins.txt" ]]; then
    cp -f "${DOTFILES_DIR}/Nix/.zsh_plugins.txt" "${HOME}/.zsh_plugins.txt" || {
      log_warning "Failed to copy .zsh_plugins.txt."
    }
  else
    # provide a sane default
    cat >"${HOME}/.zsh_plugins.txt" <<'EOF'
# Example plugins; adjust to taste
zsh-users/zsh-autosuggestions
zsh-users/zsh-completions
zsh-users/zsh-syntax-highlighting
EOF
  fi

  # macOS-specific iCloud/Downloads symlinks are skipped on Debian.

  # Starship prompt config
  install_starship_prompt

  log_success "Configuration files installed."
}

install_starship_prompt() {
  log_info "Configuring Starship prompt..."
  mkdir -p "${HOME}/.config"

  if [[ -f "${DOTFILES_DIR}/starship.toml" ]]; then
    cp -f "${DOTFILES_DIR}/starship.toml" "${HOME}/.config/starship.toml" || {
      log_warning "Failed to copy starship.toml"
    }
    log_success "Copied starship.toml to ~/.config/"
  else
    log_warning "starship.toml not found in dotfiles; fetching a minimal preset..."
    curl -fsSL https://starship.rs/presets/toml/minimal.toml > "${HOME}/.config/starship.toml" || {
      log_warning "Failed to fetch starship preset; leaving default."
    }
  fi

  log_success "Starship prompt configured."
}

configure_git() {
  log_info "Configuring git..."
  if ! command -v git >/dev/null 2>&1; then
    log_error "Git is not installed. Cannot configure git."
    return 1
  fi

  local editor
  if command -v code >/dev/null 2>&1; then
    editor="code --wait"
  else
    editor="vim"
  fi

  git config --global core.editor "${editor}"
  git config --global user.name "${GIT_USER_NAME}"
  git config --global user.email "${GIT_USER_EMAIL}"

  log_success "Git configured."
}

configure_zsh() {
  log_info "Configuring zsh as the default shell..."

  local zsh_path
  zsh_path="$(command -v zsh || true)"
  if [[ -z "${zsh_path}" ]]; then
    log_error "zsh not found; ensure it is installed."
    return 1
  fi

  # Ensure zsh is in /etc/shells
  if ! grep -q "^${zsh_path}$" /etc/shells 2>/dev/null; then
    log_info "Adding ${zsh_path} to /etc/shells..."
    echo "${zsh_path}" | sudo tee -a /etc/shells >/dev/null || {
      log_error "Failed to add zsh to /etc/shells."
      return 1
    }
  fi

  # Change default shell
  if [[ "${SHELL:-}" != "${zsh_path}" ]]; then
    log_info "Changing default shell to ${zsh_path}..."
    chsh -s "${zsh_path}" || {
      log_warning "Failed to change default shell. You may need to run: chsh -s ${zsh_path}"
    }
  fi

  log_success "zsh configured as default shell."
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
  echo "========================================="
  echo "  Debian (Trixie) Dotfiles Installation"
  echo "========================================="
  echo

  check_system_compatibility
  install_updates
  install_apt_packages
  install_antidote
  install_binary_scripts
  install_config_files
  configure_zsh
  configure_git

  echo
  echo "====================================="
  log_success "Dotfiles installation complete!"
  echo "====================================="
  echo "🎉 Restart your terminal to see the changes."

  if confirm "Open a new zsh login shell now?"; then
    exec "$(command -v zsh)" -l
  fi
}

main "$@"

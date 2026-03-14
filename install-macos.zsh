#!/usr/bin/env zsh
# =============================================================================
#
#  Dotfiles Installer Script for macOS
#
#  Author: AnalogCyan
#  License: Unlicense
#
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

usage() {
  cat <<'EOF'
Usage: ./install-macos.zsh [options]

Options:
  -h, --help    Show this help message and exit

This script installs dotfiles and configures a macOS environment.
EOF
}

while [[ "${#}" -gt 0 ]]; do
  case "${1}" in
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: Unknown option: ${1}"; usage; exit 1 ;;
  esac
done

# =============================================================================
# CONFIGURATION
# =============================================================================

BREW_FORMULAE=(
  "antidote"
  "bat"
  "btop"
  "python@3.13"
  "fd"
  "fortune"
  "fzf"
  "helix"
  "lazygit"
  "ripgrep"
  "starship"
  "thefuck"
  "xz"
  "yt-dlp"
  "zoxide"
  "zsh"
  "eza"
  "ctop"
  "git"
  "tmux"
)

BREW_CASKS=(
  "1password"
  "tailscale-app"
  "balenaetcher"
  "crystalfetch"
  "iina"
  "mactracker"
  "raspberry-pi-imager"
  "utm"
  "xcodes-app"
  "xiv-on-mac"
  "visual-studio-code@insiders"
  "iterm2"
  "keka"
  "kekaexternalhelper"
)

DOTFILES_DIR="${0:A:h}"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}INFO:${NC}    ${1}" }
log_success() { echo -e "${GREEN}SUCCESS:${NC} ${1}" }
log_warning() { echo -e "${YELLOW}WARNING:${NC} ${1}" }
log_error()   { echo -e "${RED}ERROR:${NC}   ${1}" }

confirm() {
  read "REPLY?${1:-Continue?} (y/n) "
  case "${REPLY}" in
    [yY]*) return 0 ;;
    *)     return 1 ;;
  esac
}

# =============================================================================
# SYSTEM CHECKS
# =============================================================================

check_system_compatibility() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    log_error "This installer only supports macOS."
    exit 1
  fi

  if [[ "$(uname -m)" != "arm64" ]]; then
    log_error "Apple Silicon (arm64) required. Detected: $(uname -m)"
    exit 1
  fi

  log_success "Apple Silicon macOS detected."
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

install_updates() {
  log_info "Checking for macOS system updates..."
  sudo softwareupdate -ia --force --verbose || {
    log_warning "Some macOS updates may have failed."
  }

  if command -v brew &>/dev/null; then
    log_info "Updating Homebrew..."
    brew update && brew upgrade && brew cleanup || {
      log_warning "Homebrew update/upgrade had issues."
    }
  fi

  log_success "System update completed."
}

install_homebrew() {
  if command -v brew &>/dev/null; then
    log_info "Homebrew already installed."
    eval "$($(brew --prefix)/bin/brew shellenv)"
    return
  fi

  log_info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
    log_error "Failed to install Homebrew."
    exit 1
  }

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"${HOME}/.zprofile"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  log_success "Homebrew installed."
}

install_homebrew_packages() {
  log_info "Installing formulae..."
  brew install "${BREW_FORMULAE[@]}" || log_warning "Some formulae failed."

  log_info "Installing casks..."
  brew install --cask "${BREW_CASKS[@]}" || log_warning "Some casks failed."

  log_success "Packages installed."
}

deploy_dotfiles() {
  log_info "Deploying dotfiles..."

  if [[ -f "${HOME}/.zshrc" && ! -L "${HOME}/.zshrc" ]]; then
    log_info "Backing up existing .zshrc to .zshrc.dotbak"
    mv "${HOME}/.zshrc" "${HOME}/.zshrc.dotbak"
  fi

  mkdir -p \
    "${HOME}/.config/zsh/functions" \
    "${HOME}/.zsh.d" \
    "${HOME}/Library/Application Support/Code - Insiders/User"

  rsync -av --no-perms \
    "${DOTFILES_DIR}/macos/home/" \
    "${HOME}/" || {
    log_error "Failed to rsync dotfiles."
    return 1
  }

  log_info "Installing pfetch..."
  curl -fsSL https://raw.githubusercontent.com/dylanaraps/pfetch/master/pfetch -o /tmp/pfetch && \
    sudo install -m 755 /tmp/pfetch /usr/local/bin/pfetch && \
    rm /tmp/pfetch || log_warning "Failed to install pfetch."

  log_success "Dotfiles deployed."
}

install_nerd_fonts() {
  log_info "Installing Monaspace Nerd Font..."
  local font_dir="${HOME}/Library/Fonts/Monaspace"
  local zip_path="/tmp/Monaspace.zip"

  mkdir -p "${font_dir}"
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Monaspace.zip" \
    -o "${zip_path}" || { log_warning "Failed to download Monaspace Nerd Font."; return; }
  unzip -o "${zip_path}" -d "${font_dir}" || log_warning "Failed to extract Monaspace Nerd Font."
  rm -f "${zip_path}"
  log_success "Monaspace Nerd Font installed."
}

setup_icloud_links() {
  log_info "Creating iCloud symlinks..."
  ln -snf "${HOME}/Library/Mobile Documents/com~apple~CloudDocs" "${HOME}/iCloud" || {
    log_warning "Failed to create iCloud symlink."
  }

  local downloads_target="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Downloads"
  if [[ -d "${downloads_target}" ]]; then
    if [[ -e "${HOME}/Downloads" && ! -L "${HOME}/Downloads" ]]; then
      if [[ -z "$(ls -A "${HOME}/Downloads" 2>/dev/null)" ]]; then
        sudo rm -rf "${HOME}/Downloads"
      else
        if confirm "Downloads is not empty. Replace with iCloud symlink?"; then
          sudo rm -rf "${HOME}/Downloads"
        else
          log_warning "Skipped replacing Downloads directory."
          return
        fi
      fi
    fi
    ln -snf "${downloads_target}" "${HOME}/Downloads" || {
      log_warning "Failed to create Downloads symlink."
    }
  fi
}

configure_zsh() {
  log_info "Configuring Homebrew zsh as default shell..."

  local brew_zsh
  brew_zsh="$(brew --prefix)/bin/zsh"

  if [[ ! -f "${brew_zsh}" ]]; then
    log_error "Homebrew zsh not found at ${brew_zsh}"
    return 1
  fi

  if ! grep -q "${brew_zsh}" /etc/shells; then
    echo "${brew_zsh}" | sudo tee -a /etc/shells >/dev/null || {
      log_error "Failed to add Homebrew zsh to /etc/shells."
      return 1
    }
  fi

  chsh -s "${brew_zsh}" || {
    log_error "Failed to change default shell."
    return 1
  }

  log_success "Homebrew zsh configured as default shell."
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
  echo "====================================="
  echo "  macOS Dotfiles Installation"
  echo "====================================="
  echo

  check_system_compatibility
  install_updates
  install_homebrew
  install_homebrew_packages
  install_nerd_fonts
  configure_zsh
  deploy_dotfiles
  setup_icloud_links

  echo
  echo "====================================="
  log_success "Dotfiles installation complete!"
  echo "====================================="
  echo "Restart your terminal to see the changes."
}

main "$@"

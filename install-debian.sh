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

usage() {
  cat <<'EOF'
Usage: ./install-debian.sh [options]

Options:
  -h, --help    Show this help message and exit

This script installs dotfiles and configures a Debian (Trixie) environment.
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

declare -a APT_PACKAGES=(
  bat
  btop
  fd-find
  fortune-mod
  fzf
  hx
  lazygit
  ripgrep
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
  rsync
)

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# =============================================================================
# SYSTEM CHECKS
# =============================================================================

check_system_compatibility() {
  if [[ -n "${SUDO_USER:-}" ]]; then
    log_error "Do not run this script with sudo. It will escalate only when needed."
    exit 1
  fi

  if [[ "${EUID}" -eq 0 ]]; then
    log_error "Running as root is not supported; please rerun as a regular user."
    exit 1
  fi

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    log_info "Detected OS: ${NAME:-Unknown} (${ID:-unknown}) codename=${VERSION_CODENAME:-}"

    if [[ "${ID:-}" != "debian" ]]; then
      log_warning "This script targets Debian. Proceeding anyway."
    fi
    if [[ -n "${VERSION_CODENAME:-}" && "${VERSION_CODENAME}" != "trixie" ]]; then
      log_warning "Tuned for Debian 'trixie', but you are on '${VERSION_CODENAME}'. Continuing."
    fi
  else
    log_warning "/etc/os-release not found; proceeding blindly."
  fi
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

install_updates() {
  log_info "Updating system..."
  sudo apt update || log_warning "apt update failed"
  sudo apt -y full-upgrade || log_warning "apt full-upgrade had issues"
  sudo apt -y autoremove || true
  sudo apt -y autoclean || true
  log_success "System update completed."
}

install_apt_packages() {
  log_info "Installing packages..."
  sudo apt install -y --no-install-recommends "${APT_PACKAGES[@]}" || {
    log_warning "Some packages failed to install."
  }
  log_success "Packages installed."
}

install_antidote() {
  local target="${HOME}/.antidote"
  if [[ -d "${target}/.git" ]]; then
    log_info "Updating Antidote..."
    git -C "${target}" pull --ff-only || log_warning "Failed to update Antidote."
  else
    log_info "Installing Antidote..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "${target}" || {
      log_warning "Failed to clone Antidote."
    }
  fi
}

install_vscode() {
  log_info "Installing VS Code Insiders..."
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
    sudo gpg --dearmor -o /usr/share/keyrings/packages-microsoft-com.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/packages-microsoft-com.gpg] \
    https://packages.microsoft.com/repos/code stable main" | \
    sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
  sudo apt update
  sudo apt install -y code-insiders || log_warning "Failed to install VS Code Insiders."
  log_success "VS Code Insiders installed."
}

install_ctop() {
  log_info "Installing ctop..."
  sudo apt install -y ca-certificates curl gnupg lsb-release
  curl -fsSL https://azlux.fr/repo.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/azlux-archive-keyring.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian \
    $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/azlux.list >/dev/null
  sudo apt update
  sudo apt install -y docker-ctop || log_warning "Failed to install ctop."
}

deploy_dotfiles() {
  log_info "Deploying dotfiles..."

  if [[ -f "${HOME}/.zshrc" && ! -L "${HOME}/.zshrc" ]]; then
    log_info "Backing up existing .zshrc to .zshrc.dotbak"
    mv -f "${HOME}/.zshrc" "${HOME}/.zshrc.dotbak"
  fi

  mkdir -p \
    "${HOME}/.config/zsh/functions" \
    "${HOME}/.zsh.d" \
    "${HOME}/.config/Code - Insiders/User"

  rsync -av --no-perms \
    "${DOTFILES_DIR}/debian/home/" \
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

configure_zsh() {
  log_info "Configuring zsh as default shell..."

  local zsh_path
  zsh_path="$(command -v zsh || true)"
  if [[ -z "${zsh_path}" ]]; then
    log_error "zsh not found."
    return 1
  fi

  if ! grep -q "^${zsh_path}$" /etc/shells 2>/dev/null; then
    echo "${zsh_path}" | sudo tee -a /etc/shells >/dev/null || {
      log_error "Failed to add zsh to /etc/shells."
      return 1
    }
  fi

  if [[ "${SHELL:-}" != "${zsh_path}" ]]; then
    chsh -s "${zsh_path}" || {
      log_warning "Failed to change default shell. Run manually: chsh -s ${zsh_path}"
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
  install_vscode
  install_ctop
  deploy_dotfiles
  configure_zsh

  echo
  echo "====================================="
  log_success "Dotfiles installation complete!"
  echo "====================================="
  echo "Restart your terminal to see the changes."

  if confirm "Open a new zsh login shell now?"; then
    exec "$(command -v zsh)" -l
  fi
}

main "$@"

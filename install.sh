#!/usr/bin/env bash
# =============================================================================
#
#  Dotfiles Installer for macOS and Debian (Trixie)
#
#  Author: AnalogCyan
#  License: Unlicense
#
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  -h, --help    Show this help message and exit

This script installs dotfiles and configures a macOS or Debian environment.
EOF
}

while [[ "${#}" -gt 0 ]]; do
  case "${1}" in
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: Unknown option: ${1}"; usage; exit 1 ;;
  esac
done

# =============================================================================
# ENVIRONMENT
# =============================================================================

OS="$(uname -s)"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}"

# =============================================================================
# CONFIGURATION
# =============================================================================

BREW_FORMULAE=(
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

declare -a APT_PACKAGES=(
  bat
  btop
  fd-find
  fortune-mod
  fzf
  gnupg
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
  tmux
  git
  curl
  ca-certificates
  rsync
  unzip
)

ZSH_PLUGIN_URLS=(
  "https://github.com/unixorn/fzf-zsh-plugin"
  "https://github.com/Aloxaf/fzf-tab"
  "https://github.com/zsh-users/zsh-history-substring-search"
  "https://github.com/zsh-users/zsh-autosuggestions"
  "https://github.com/ajeetdsouza/zoxide"
  "https://github.com/mollifier/cd-gitroot"
  "https://github.com/zdharma-continuum/fast-syntax-highlighting"
  "https://github.com/hlissner/zsh-autopair"
  "https://github.com/MichaelAquilina/zsh-you-should-use"
  "https://github.com/z-shell/zsh-eza"
)

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

declare -a STEP_LABELS=()
declare -a STEP_CODES=()

run_step() {
  local label="$1"
  local code=0
  shift

  if "$@"; then
    code=0
  else
    code=$?
  fi

  STEP_LABELS+=("$label")
  STEP_CODES+=("$code")

  (( code <= 1 ))
}

print_install_summary() {
  [[ "${#STEP_LABELS[@]}" -eq 0 ]] && return

  local i label code
  local had_warnings=0
  local had_failures=0

  echo
  echo "====================================="
  echo "  Install Summary"
  echo "====================================="

  for i in "${!STEP_LABELS[@]}"; do
    label="${STEP_LABELS[$i]}"
    code="${STEP_CODES[$i]}"
    case "${code}" in
      0)
        printf '%bOK%b    %s\n' "${GREEN}" "${NC}" "${label}"
        ;;
      1)
        printf '%bWARN%b  %s\n' "${YELLOW}" "${NC}" "${label}"
        had_warnings=1
        ;;
      *)
        printf '%bFAIL%b  %s\n' "${RED}" "${NC}" "${label}"
        had_failures=1
        ;;
    esac
  done

  echo "====================================="
  if (( had_failures )); then
    log_error "Installation stopped with failures."
  elif (( had_warnings )); then
    log_warning "Installation finished with warnings."
  else
    log_success "Installation finished successfully."
  fi
}

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
  case "${OS}" in
    Darwin)
      if [[ "$(uname -m)" != "arm64" ]]; then
        log_error "Apple Silicon (arm64) required. Detected: $(uname -m)"
        return 2
      fi
      log_success "Apple Silicon macOS detected."
      ;;
    Linux)
      if [[ -n "${SUDO_USER:-}" ]]; then
        log_error "Do not run this script with sudo. It will escalate only when needed."
        return 2
      fi
      if [[ "${EUID}" -eq 0 ]]; then
        log_error "Running as root is not supported; please rerun as a regular user."
        return 2
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
      ;;
    *)
      log_error "Unsupported OS: ${OS}. Supports macOS (Darwin) and Linux (Debian)."
      return 2
      ;;
  esac
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
    brew update && brew upgrade && brew cleanup || {
      log_warning "Homebrew update/upgrade had issues."
      status=1
    }
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
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
    log_error "Failed to install Homebrew."
    return 2
  }

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"${HOME}/.zprofile"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  log_success "Homebrew installed."
}

install_homebrew_packages() {
  local status=0
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
        sudo rm -rf "${HOME}/Downloads"
      else
        if confirm "Downloads is not empty. Replace with iCloud symlink?"; then
          sudo rm -rf "${HOME}/Downloads"
        else
          log_warning "Skipped replacing Downloads directory."
          status=1
          return "${status}"
        fi
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

# =============================================================================
# DEBIAN FUNCTIONS
# =============================================================================

install_updates_debian() {
  local status=0
  log_info "Updating system..."
  sudo rm -f /usr/share/keyrings/microsoft.gpg
  sudo grep -rl 'packages.microsoft.com/repos/code' /etc/apt/sources.list.d/ 2>/dev/null \
    | xargs -r sudo rm -f || true
  sudo apt update || {
    log_warning "apt update failed"
    status=1
  }
  sudo apt -y full-upgrade || {
    log_warning "apt full-upgrade had issues"
    status=1
  }
  sudo apt -y autoremove || true
  sudo apt -y autoclean || true
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
  sudo apt install -y --no-install-recommends "${APT_PACKAGES[@]}" || {
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

install_vscode() {
  local status=0
  log_info "Installing VS Code Insiders..."
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
    sudo gpg --yes --dearmor -o /usr/share/keyrings/packages-microsoft-com.gpg || status=1
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/packages-microsoft-com.gpg] \
    https://packages.microsoft.com/repos/code stable main" | \
    sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null || status=1
  sudo apt update || status=1
  sudo apt install -y code-insiders || {
    log_warning "Failed to install VS Code Insiders."
    status=1
  }
  if (( status == 0 )); then
    log_success "VS Code Insiders installed."
  else
    log_warning "VS Code Insiders setup finished with warnings."
  fi

  return "${status}"
}

install_ctop() {
  log_info "Installing ctop..."
  local arch latest
  arch=$(dpkg --print-architecture)
  latest=$(curl -fsSL "https://api.github.com/repos/bcicen/ctop/releases/latest" | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
  if [[ -z "${latest}" ]]; then
    log_warning "Could not determine ctop version; skipping."
    return 1
  fi
  curl -fsSL "https://github.com/bcicen/ctop/releases/download/${latest}/ctop-${latest#v}-linux-${arch}" \
    -o /tmp/ctop && \
    sudo install -m 755 /tmp/ctop /usr/local/bin/ctop && \
    rm /tmp/ctop || {
      log_warning "ctop installation finished with warnings."
      return 1
    }

  if [[ -x /usr/local/bin/ctop ]]; then
    log_success "ctop installed."
  else
    log_warning "ctop installation finished with warnings."
    return 1
  fi
}

# =============================================================================
# SHARED FUNCTIONS
# =============================================================================

install_zsh_plugins() {
  local plugins_dir="${HOME}/.local/share/zsh/plugins"
  local failures=0
  log_info "Installing zsh plugins..."
  mkdir -p "${plugins_dir}"

  for url in "${ZSH_PLUGIN_URLS[@]}"; do
    local name
    name=$(basename "${url}")
    if [[ -d "${plugins_dir}/${name}/.git" ]]; then
      log_info "Updating ${name}..."
      git -C "${plugins_dir}/${name}" pull --ff-only || {
        log_warning "Failed to update ${name}."
        failures=$((failures + 1))
      }
    else
      log_info "Cloning ${name}..."
      git clone --depth=1 "${url}" "${plugins_dir}/${name}" || {
        log_warning "Failed to clone ${name}."
        failures=$((failures + 1))
      }
    fi
  done

  if (( failures == 0 )); then
    log_success "Zsh plugins installed."
  else
    log_warning "Zsh plugin installation finished with ${failures} warning(s)."
  fi

  (( failures == 0 ))
}

install_nerd_fonts() {
  log_info "Installing Monaspace Nerd Font..."
  local font_dir zip_path
  case "${OS}" in
    Darwin) font_dir="${HOME}/Library/Fonts/Monaspace" ;;
    Linux)  font_dir="${HOME}/.fonts/Monaspace" ;;
  esac
  zip_path="/tmp/Monaspace.zip"

  mkdir -p "${font_dir}"
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Monaspace.zip" \
    -o "${zip_path}" || { log_warning "Failed to download Monaspace Nerd Font."; return 1; }
  unzip -o "${zip_path}" -d "${font_dir}" || {
    log_warning "Failed to extract Monaspace Nerd Font."
    rm -f "${zip_path}"
    return 1
  }
  rm -f "${zip_path}"

  if [[ "${OS}" == "Linux" ]]; then
    fc-cache -fv || {
      log_warning "Failed to refresh font cache."
      return 1
    }
  fi

  log_success "Monaspace Nerd Font installed."
}

deploy_dotfiles() {
  log_info "Deploying dotfiles..."
  local status=0

  if [[ -f "${HOME}/.zshrc" && ! -L "${HOME}/.zshrc" ]]; then
    log_info "Backing up existing .zshrc to .zshrc.dotbak"
    mv -f "${HOME}/.zshrc" "${HOME}/.zshrc.dotbak"
  fi

  mkdir -p \
    "${HOME}/.config/zsh/functions" \
    "${HOME}/.zsh.d"

  rsync -av --no-perms "${DOTFILES_DIR}/shared/home/" "${HOME}/" || {
    log_error "Failed to rsync shared dotfiles."
    return 2
  }

  local vscode_dir
  case "${OS}" in
    Darwin)
      if [[ -d "${DOTFILES_DIR}/macos/home" ]]; then
        rsync -av --no-perms "${DOTFILES_DIR}/macos/home/" "${HOME}/" || {
          log_error "Failed to rsync macOS overlay."
          return 2
        }
      fi
      vscode_dir="${HOME}/Library/Application Support/Code - Insiders/User"
      ;;
    Linux)
      vscode_dir="${HOME}/.config/Code - Insiders/User"
      ;;
  esac

  mkdir -p "${vscode_dir}"
  cp "${DOTFILES_DIR}/shared/vscode/settings.json" "${vscode_dir}/settings.json" || {
    log_warning "Failed to copy VS Code settings."
    status=1
  }

  log_info "Installing pfetch..."
  curl -fsSL https://raw.githubusercontent.com/dylanaraps/pfetch/master/pfetch -o /tmp/pfetch && \
    sudo install -m 755 /tmp/pfetch /usr/local/bin/pfetch && \
    rm /tmp/pfetch || {
      log_warning "Failed to install pfetch."
      status=1
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

  if ! grep -q "^${zsh_path}$" /etc/shells 2>/dev/null; then
    echo "${zsh_path}" | sudo tee -a /etc/shells >/dev/null || {
      log_error "Failed to add zsh to /etc/shells."
      return 2
    }
  fi

  if [[ "${SHELL:-}" != "${zsh_path}" ]]; then
    chsh -s "${zsh_path}" || {
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
# MAIN EXECUTION
# =============================================================================

main() {
  local failed=0

  echo "====================================="
  echo "  Dotfiles Installation (${OS})"
  echo "====================================="
  echo

  if run_step "System compatibility" check_system_compatibility; then
    case "${OS}" in
      Darwin)
        run_step "macOS updates" install_updates_macos && \
        run_step "Homebrew" install_homebrew && \
        run_step "Homebrew packages" install_homebrew_packages && \
        run_step "zsh plugins" install_zsh_plugins && \
        run_step "Monaspace Nerd Font" install_nerd_fonts && \
        run_step "Default zsh shell" configure_zsh && \
        run_step "Dotfile deployment" deploy_dotfiles && \
        run_step "iCloud links" setup_icloud_links || failed=1
        ;;
      Linux)
        run_step "Debian updates" install_updates_debian && \
        run_step "APT packages" install_apt_packages && \
        run_step "zsh plugins" install_zsh_plugins && \
        run_step "VS Code Insiders" install_vscode && \
        run_step "ctop" install_ctop && \
        run_step "Monaspace Nerd Font" install_nerd_fonts && \
        run_step "Dotfile deployment" deploy_dotfiles && \
        run_step "Default zsh shell" configure_zsh || failed=1
        ;;
    esac
  else
    failed=1
  fi

  print_install_summary

  if (( failed == 0 )); then
    echo "Restart your terminal to see the changes."
  fi

  if (( failed == 0 )) && [[ "${OS}" == "Linux" ]]; then
    if confirm "Open a new zsh login shell now?"; then
      exec "$(command -v zsh)" -l
    fi
  fi

  return "${failed}"
}

main "$@"

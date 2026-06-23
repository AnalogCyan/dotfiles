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

# Cleanup temp files on exit or interrupt
cleanup() {
  rm -f /tmp/pfetch /tmp/zmx.tar.gz /tmp/ctop /tmp/Monaspace.zip
}
trap cleanup EXIT INT TERM

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
  "anomalyco/tap/opencode"
  "bat"
  "btop"
  "chojs23/tap/concord"
  "ctop"
  "eza"
  "fd"
  "fortune"
  "fzf"
  "git"
  "gromgit/brewtils/taproom"
  "helix"
  "lazygit"
  "neurosnap/tap/zmx"
  "philocalyst/tap/caligula"
  "python@3.13"
  "ripgrep"
  "starship"
  "tmux"
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
  "balenaetcher"
  "crystalfetch"
  "iina"
  "keka"
  "kekaexternalhelper"
  "mactracker"
  "raspberry-pi-imager"
  "tailscale-app"
  "utm"
  "xcodes-app"
  "zed@preview"
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
  git
  gnupg
  hx
  jq
  lazygit
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
          log_warning "This script targets Debian. Many parts may not work on ${NAME:-this distro}."
          if ! confirm "Continue as generic Linux install?"; then
            log_info "Aborted by user."
            return 2
          fi
        fi
        if [[ -n "${VERSION_CODENAME:-}" && "${VERSION_CODENAME}" != "trixie" ]]; then
          log_warning "Tuned for Debian 'trixie', but you are on '${VERSION_CODENAME}'. Continuing."
        fi
      else
        log_warning "/etc/os-release not found; proceeding blindly."
        if ! confirm "Continue as generic Linux install?"; then
          log_info "Aborted by user."
          return 2
        fi
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
        rm -rf "${HOME}/Downloads"
      else
        if confirm "Downloads is not empty. Replace with iCloud symlink?"; then
          rm -rf "${HOME}/Downloads"
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
  sudo apt modernize-sources || {
    log_warning "Failed to modernize sources."
    status=1
  }
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

  asset_url=$(curl -fsSL "https://api.github.com/repos/Gobidev/pfetch-rs/releases/latest" \
    | jq -r --arg arch "${pfetch_arch}" \
      '.assets[] | select(.name | test("pfetch-linux-musl-" + $arch + "\\.tar\\.gz$")) | .browser_download_url')

  if [[ -z "${asset_url}" || "${asset_url}" == "null" ]]; then
    log_warning "No pfetch-rs binary found for ${pfetch_arch}; skipping."
    return 1
  fi

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

  # mkasberg is the only repo with arm64 + Forky builds
  asset_url=$(curl -fsSL "https://api.github.com/repos/mkasberg/ghostty-ubuntu/releases/latest" \
    | jq -r --arg arch "${deb_arch}" --arg codename "${codename}" \
      '.assets[] | select(.name | test("_" + $arch + "_" + $codename + "\\.deb$")) | .browser_download_url' \
    | head -n1)

  if [[ -z "${asset_url}" || "${asset_url}" == "null" ]]; then
    log_warning "No Ghostty .deb found for ${deb_arch}/${codename}"
    return 1
  fi

  log_info "Downloading Ghostty from ${asset_url}..."
  tmp_deb=$(mktemp /tmp/ghostty-XXXXXX.deb)
  curl -fsSL "${asset_url}" -o "${tmp_deb}" || {
    log_warning "Failed to download Ghostty."
    rm -f "${tmp_deb}"
    return 1
  }

sudo dpkg -i "${tmp_deb}" || {
    log_warning "dpkg failed, attempting dependency fix..."
    sudo apt-get install -f -y
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
  curl -f https://zed.dev/install.sh | ZED_CHANNEL=preview sh || {
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
  local arch zmx_arch latest zip_path
  arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
  case "${arch}" in
    amd64|x86_64) zmx_arch="x86_64" ;;
    arm64|aarch64) zmx_arch="aarch64" ;;
    *)
      log_warning "Unsupported architecture for zmx: ${arch}; skipping."
      return 1
      ;;
  esac

  latest=$(curl -fsSL "https://api.github.com/repos/neurosnap/zmx/tags" | jq -r '.[0].name // empty')
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

  latest=$(curl -fsSL "https://api.github.com/repos/bcicen/ctop/releases/latest" | jq -r '.tag_name // empty')
  if [[ -z "${latest}" ]]; then
    log_warning "Could not determine ctop version; skipping."
    return 1
  fi
  tmp_dir=$(mktemp -d)
  binary_path="${tmp_dir}/ctop"
  curl -fsSL "https://github.com/bcicen/ctop/releases/download/${latest}/ctop-${latest#v}-linux-${arch}" -o "${binary_path}" && \
    sudo install -m 755 "${binary_path}" /usr/local/bin/ctop || {
      log_warning "ctop installation finished with warnings."
      rm -rf "${tmp_dir}"
      return 1
    }

  rm -rf "${tmp_dir}"

  if [[ -x /usr/local/bin/ctop ]]; then
    log_success "ctop installed."
  else
    log_warning "ctop installation finished with warnings."
    return 1
  fi
}

install_croc() {
    log_info "Installing croc..."
    curl https://getcroc.schollz.com | bash
}

install_yazi() {
  log_info "Installing yazi..."
  local arch latest_tag deb_arch deb_url deb_file
  arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
  case "${arch}" in
    amd64|x86_64) deb_arch="x86_64-unknown-linux-gnu" ;;
    arm64|aarch64) deb_arch="aarch64-unknown-linux-gnu" ;;
    *)
      log_warning "Unsupported architecture for yazi: ${arch}; skipping."
      return 1
      ;;
  esac

  latest_tag=$(curl -fsSL "https://api.github.com/repos/sxyazi/yazi/releases/latest" | jq -r '.tag_name // empty')
  if [[ -z "${latest_tag}" ]]; then
    log_warning "Could not determine yazi version; skipping."
    return 1
  fi

  deb_url="https://github.com/sxyazi/yazi/releases/download/${latest_tag}/yazi-${deb_arch}.deb"
  deb_file="/tmp/yazi-${deb_arch}.deb"

  curl -fsSL "${deb_url}" -o "${deb_file}" && \
    sudo dpkg -i "${deb_file}" && \
    rm -f "${deb_file}" || {
      log_warning "yazi installation finished with warnings."
      rm -f "${deb_file}"
      return 1
    }

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

install_zsh_plugins() {
  local plugins_file="${DOTFILES_DIR}/home/.zsh_plugins.txt"
  local plugins_dir="${HOME}/.local/share/zsh/plugins"
  local failures=0
  log_info "Installing zsh plugins..."
  mkdir -p "${plugins_dir}"

  if [[ ! -f "${plugins_file}" ]]; then
    log_error "Plugin manifest file not found: ${plugins_file}"
    return 2
  fi

  while read -r line || [[ -n "$line" ]]; do
    # Remove leading/trailing whitespace and comments
    line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    local name url is_git=true
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
        is_git=false
      fi
    else
      name=$(basename "$line")
      url="https://github.com/${line}"
    fi

    local target_dir="${plugins_dir}/${name}"
    if $is_git; then
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
  done < "${plugins_file}"

  if (( failures == 0 )); then
    log_success "Zsh plugins installed."
  else
    log_warning "Zsh plugin installation finished with ${failures} warning(s)."
  fi

  (( failures == 0 ))
}

install_nerd_fonts() {
  log_info "Installing Monaspace Nerd Font..."
  local font_dir tmp_dir zip_path
  case "${OS}" in
    Darwin) font_dir="${HOME}/Library/Fonts/Monaspace" ;;
    Linux)  font_dir="${HOME}/.fonts/Monaspace" ;;
  esac

  mkdir -p "${font_dir}"
  tmp_dir=$(mktemp -d)
  zip_path="${tmp_dir}/Monaspace.zip"

  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Monaspace.zip" \
    -o "${zip_path}" || { log_warning "Failed to download Monaspace Nerd Font."; rm -rf "${tmp_dir}"; return 1; }
  unzip -o "${zip_path}" -d "${font_dir}" || {
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
  local backup_dir="${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
  local found_any=0

  while IFS= read -r -d '' file; do
    local rel_path="${file#${DOTFILES_DIR}/home/}"
    local target="${HOME}/${rel_path}"
    if [[ -f "$target" && ! -L "$target" ]]; then
      [[ "$found_any" -eq 0 ]] && { mkdir -p "$backup_dir"; found_any=1; }
      mkdir -p "$(dirname "${backup_dir}/${rel_path}")"
      cp -a "$target" "${backup_dir}/${rel_path}"
    fi
  done < <(find "${DOTFILES_DIR}/home" -type f -print0)

  if (( found_any )); then
    log_info "Existing dotfiles backed up to ${backup_dir}"
  fi
}

deploy_dotfiles() {
  log_info "Deploying dotfiles..."
  local status=0

  backup_existing_dotfiles

  mkdir -p \
    "${HOME}/.config/zsh/functions" \
    "${HOME}/.zsh.d"

  rsync -av --no-perms "${DOTFILES_DIR}/home/" "${HOME}/" || {
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
        run_step "iCloud links" setup_icloud_links && \
        run_step "Ghostty config" setup_ghostty_config || failed=1
        ;;
      Linux)
        run_step "Debian updates" install_updates_debian && \
        run_step "APT packages" install_apt_packages && \
        run_step "pfetch-rs" install_pfetch_rs && \
        run_step "zsh plugins" install_zsh_plugins && \
        run_step "Ghostty" install_ghostty && \
        run_step "Zed" install_zed && \
        run_step "ctop" install_ctop && \
        run_step "zmx" install_zmx_linux && \
        run_step "croc" install_croc && \
        run_step "yazi" install_yazi && \
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

  return "${failed}"
}

main "$@"

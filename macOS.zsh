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
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -h, --help    Show this help message and exit"
  echo
  echo "This script installs dotfiles and configures your macOS environment."
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# =============================================================================
# CONFIGURATION
# =============================================================================

# Homebrew package lists
BREW_FORMULAE=(
  "antidote"                              # Plugin manager for zsh
  "bat"                                   # Cat clone with syntax highlighting and Git integration
  "btop"                                  # Resource monitor with CPU, memory, disk, and network usage
  "fortune"                               # Random quotations program
  "fzf"                                   # Command-line fuzzy finder
  "lazygit"                               # Simple terminal UI for git commands
  "starship"                              # Cross-shell prompt customization
  "thefuck"                               # Magnificent app which corrects your previous console command
  "xz"                                    # General-purpose data compression tool
  "yt-dlp"                                # Fork of youtube-dl with additional features
  "zoxide"                                # Smarter cd command with learning abilities
  "zsh"                                   # Z shell, a powerful shell with scripting capabilities
  "eza"                                   # A modern replacement for 'ls'
  "ctop"                                  # A top-like interface for container metrics
)

BREW_CASKS=(
  "1password"                             # 1Password app for password management
  "1password-cli"                         # 1Password CLI for command-line access
  "tailscale-app"                         # Tailscale app for secure networking
  "chatgpt"                               # ChatGPT app for conversational AI
  "font-fira-code-nerd-font"              # FiraCode patched with Nerd Font icons
  "font-hack-nerd-font"                   # Hack Nerd Font for additional glyph coverage
  "setapp"                                # Setapp for accessing a suite of Mac apps
  "balenaetcher"                          # Balena Etcher for flashing OS images to USB drives
  "crystalfetch"                          # CrystalFetch for downloading Windows ISO files
  "iina"                                  # IINA media player
  "mactracker"                            # MacTracker for tracking Apple hardware
  "modrinth"                              # Modrinth Minecraft app
  "raspberry-pi-imager"                   # Raspberry Pi Imager for flashing Raspberry Pi OS
  "transmission"                          # Transmission BitTorrent client
  "utm"                                   # UTM for running virtual machines
  "xcodes-app"                            # Xcodes for managing Xcode versions
  "xiv-on-mac"                            # FFXIV launcher for macOS
  "visual-studio-code"                    # Visual Studio Code editor
  "iterm2"
  "messenger"
  "affinity"
)

# Git configuration
GIT_USER_NAME="AnalogCyan"
GIT_USER_EMAIL="git@thayn.me"

# Paths
DOTFILES_DIR="${0:A:h}"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${BLUE}INFO:${NC} $1"
}

log_success() {
  echo -e "${GREEN}SUCCESS:${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}WARNING:${NC} $1"
}

log_error() {
  echo -e "${RED}ERROR:${NC} $1"
}

confirm() {
  read "REPLY?${1:-Continue?} (y/n) "
  case "$REPLY" in
    [yY]*) return 0 ;;
    *)     return 1 ;;
  esac
}

check_system_compatibility() {
  log_info "Checking system compatibility..."

  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"

  if [[ "$os" != "Darwin" ]]; then
    log_error "This installer only supports macOS."
    exit 1
  fi

  if [[ "$arch" != "arm64" ]]; then
    log_error "Apple Silicon (arm64) Mac required. Detected architecture: $arch"
    exit 1
  fi

  log_success "Apple Silicon macOS detected."
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

install_updates() {
  log_info "Ensuring system is up-to-date..."

  # Update macOS system software
  log_info "Checking for macOS system updates..."
  sudo softwareupdate -ia --force --verbose || {
    log_warning "Some macOS updates may have failed to install."
  }

  # Update Homebrew and packages if installed
  if command -v brew &>/dev/null; then
    log_info "Updating Homebrew packages..."
    brew update || {
      log_warning "Failed to update Homebrew."
    }

    # Upgrade all packages
    brew upgrade || {
      log_warning "Some Homebrew packages failed to upgrade."
    }

    # Clean up old versions
    brew cleanup || {
      log_warning "Homebrew cleanup failed."
    }
  fi

  log_success "System update process completed."
}

install_homebrew() {
  log_info "Installing Homebrew..."

  # Check if Homebrew is already installed
  if command -v brew &>/dev/null; then
    log_info "Homebrew is already installed. Updating..."
    brew update || {
      log_warning "Failed to update Homebrew."
    }
    # Load Homebrew environment into the current session
    eval "$($(brew --prefix)/bin/brew shellenv)"
  else
    log_info "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
      log_error "Failed to install Homebrew."
      exit 1
    }

    echo '# Set PATH, MANPATH, etc., for Homebrew.' >>"$HOME/.zprofile"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  log_success "Homebrew installed."
}

install_binary_scripts() {
  log_info "Installing binary scripts and utilities..."

  # Create necessary directories
  mkdir -pv ~/bin/apps/pfetch/ || {
    log_error "Failed to create bin directories."
    return 1
  }

  # Copy bin scripts
  log_info "Copying binary scripts..."
  if [ -d "$DOTFILES_DIR/Nix/bin" ]; then
    cp "$DOTFILES_DIR/Nix/bin/"* ~/bin/ || {
      log_warning "Failed to copy bin scripts."
    }
  else
    log_warning "Bin scripts directory not found."
  fi

  # Install pfetch
  log_info "Installing pfetch..."
  if [ ! -d "$HOME/bin/apps/pfetch/.git" ]; then
    git clone https://github.com/dylanaraps/pfetch.git ~/bin/apps/pfetch/ || {
      log_warning "Failed to clone pfetch repository."
    }
  else
    (cd ~/bin/apps/pfetch && git pull) || {
      log_warning "Failed to update pfetch."
    }
  fi

  # Make sure scripts are executable
  find ~/bin -type f -exec chmod +x {} \; 2>/dev/null

  log_success "Binary scripts and utilities installed."
}

install_config_files() {
  log_info "Installing configuration files..."

  # Create necessary directories
  mkdir -pv ~/.config/zsh/functions ~/.zsh.d || {
    log_warning "Failed to create zsh directories."
  }

  # Backup existing zshrc if it exists
  if [ -f "$HOME/.zshrc" ]; then
    log_info "Backing up existing .zshrc to .zshrc.dotbak"
    mv "$HOME/.zshrc" "$HOME/.zshrc.dotbak" || {
      log_warning "Failed to backup .zshrc."
    }
  fi

  # Copy configuration files
  if [ -f "$DOTFILES_DIR/Nix/.zshrc" ]; then
    cp "$DOTFILES_DIR/Nix/.zshrc" ~/.zshrc || {
      log_warning "Failed to copy .zshrc."
    }
  else
    log_error "Could not find .zshrc in the dotfiles repo."
    # Create a minimal .zshrc file with proper initialization order
    log_info "Creating a minimal .zshrc file..."
    cat >"$HOME/.zshrc" <<EOF
# =============================================================================
#  Core Configuration
# =============================================================================

# Environment Paths
export PATH=\$HOME/bin:/usr/local/bin:\$PATH

# Session Editor
export EDITOR='vim'

# =============================================================================
#  Shell Configuration
# =============================================================================

# Initialize completion system before Antidote
autoload -Uz compinit
compinit -d ~/.zcompdump

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt histignorealldups
setopt histignorespace

# =============================================================================
#  Plugin Management (Antidote)
# =============================================================================

# Initialize Antidote
source "\$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh" 2>/dev/null || source "\$HOME/.antidote/antidote.zsh"
antidote load ~/.zsh_plugins.txt

# Set completion options after plugins are loaded
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# =============================================================================
#  Tool Initializations
# =============================================================================

# Initialize modern tools
eval \$(thefuck --alias 2>/dev/null)
eval "\$(zoxide init zsh)"

# Load fzf if it exists
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Initialize Starship prompt
eval "\$(starship init zsh)"
EOF
  fi

  # Copy plugins file with updated configuration
  if [ -f "$DOTFILES_DIR/Nix/.zsh_plugins.txt" ]; then
    cp "$DOTFILES_DIR/Nix/.zsh_plugins.txt" ~/.zsh_plugins.txt || {
      log_warning "Failed to copy .zsh_plugins.txt."
    }
    log_info "Note: Deprecated plugins have been removed and replaced with maintained alternatives."
    log_info "      - zpm-zsh/1password replaced with official 1Password CLI"
    log_info "      - Docker plugins replaced with official completions"
    log_info "      - Other unmaintained plugins have been removed or replaced"
  fi

  # Copy custom functions
  if [ -d "$DOTFILES_DIR/Nix/functions" ]; then
    cp "$DOTFILES_DIR/Nix/functions/"*.zsh ~/.config/zsh/functions/ || {
      log_warning "Failed to copy zsh functions."
    }
  else
    log_error "Could not find functions directory in the dotfiles repo."
  fi

  # Create iCloud symlink
  log_info "Creating symbolic links for iCloud and Downloads..."
  ln -snfv "$HOME/Library/Mobile Documents/com~apple~CloudDocs" "$HOME/iCloud" || {
    log_warning "Failed to create iCloud symlink."
  }

  # Create Downloads symlink
  local downloads_dir="$HOME/Downloads"
  local downloads_target="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Downloads"
  local should_link_downloads="true"

  if [ -e "$downloads_dir" ] && [ ! -L "$downloads_dir" ]; then
    if [ -z "$(ls -A "$downloads_dir")" ]; then
      log_info "Existing Downloads directory is empty; removing before linking..."
      sudo rm -rf "$downloads_dir"
    else
      log_warning "Existing Downloads directory contains files."
      if confirm "Downloads is not empty. Remove it and replace with an iCloud symlink?"; then
        log_info "Removing existing Downloads directory..."
        sudo rm -rf "$downloads_dir"
      else
        log_warning "Skipped replacing Downloads directory to preserve existing files."
        should_link_downloads="false"
      fi
    fi
  fi

  if [ "$should_link_downloads" = "true" ]; then
    ln -snfv "$downloads_target" "$downloads_dir" || {
      log_warning "Failed to create Downloads symlink."
    }
  fi

  # Install and configure Starship prompt
  install_starship_prompt

  log_success "Configuration files installed."
}

install_starship_prompt() {
  log_info "Configuring Starship prompt..."

  # Create config directory if it doesn't exist
  mkdir -p ~/.config

  # Copy starship.toml from dotfiles repo to ~/.config/
  if [ -f "$DOTFILES_DIR/starship.toml" ]; then
    cp "$DOTFILES_DIR/starship.toml" ~/.config/starship.toml || {
      log_warning "Failed to copy starship.toml"
    }
    log_success "Copied starship.toml to ~/.config/"
  else
    log_error "starship.toml not found in dotfiles directory"
    # Create fallback configuration if file doesn't exist
    log_info "Creating default starship.toml configuration..."
    curl -sS https://starship.rs/presets/toml/minimal.toml >~/.config/starship.toml
  fi

  log_success "Starship prompt configured."
}

install_homebrew_packages() {
  log_info "Installing Homebrew packages..."

  # Install Homebrew formulae
  log_info "Installing Homebrew formulae..."
  for formula in "${BREW_FORMULAE[@]}"; do
    log_info "Installing $formula..."
    brew install "$formula" || {
      log_warning "Failed to install $formula."
    }
  done

  # Install Homebrew casks
  log_info "Installing Homebrew casks..."
  for cask in "${BREW_CASKS[@]}"; do
    log_info "Installing $cask..."
    brew install --cask "$cask" || {
      log_warning "Failed to install $cask."
    }
  done

  log_success "Homebrew packages installed."
}

configure_git() {
  log_info "Configuring git..."

  if ! command -v git &>/dev/null; then
    log_error "Git is not installed. Cannot configure git."
    return 1
  fi

  # Choose appropriate editor based on environment
  local editor
  if command -v code &>/dev/null; then
    editor="code --wait"
  else
    editor="vim" # Default to vim if VSCode is not installed
  fi

  git config --global core.editor "$editor"
  git config --global user.name "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"

  log_success "Git configured."
}

configure_zsh() {
  log_info "Configuring Homebrew zsh..."

  # Get the path to Homebrew's zsh
  BREW_ZSH="$(brew --prefix)/bin/zsh"

  # Ensure Homebrew zsh formula is installed
  if ! brew list zsh &>/dev/null; then
    log_info "Homebrew zsh not found; installing..."
    brew install zsh || { log_error "Failed to install Homebrew zsh"; exit 1; }
  fi

  # Check if Homebrew's zsh is installed
  if [ ! -f "$BREW_ZSH" ]; then
    log_error "Homebrew zsh not found. Please ensure it's installed."
    return 1
  fi

  # Add Homebrew's zsh to /etc/shells if it's not already there
  if ! grep -q "$BREW_ZSH" /etc/shells; then
    log_info "Adding Homebrew zsh to /etc/shells..."
    echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null || {
      log_error "Failed to add Homebrew zsh to /etc/shells."
      return 1
    }
  fi

  # Change the default shell to Homebrew's zsh
  log_info "Changing default shell to Homebrew zsh..."
  chsh -s "$BREW_ZSH" || {
    log_error "Failed to change default shell."
    return 1
  }

  log_success "Homebrew zsh configured as default shell."
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
  # Print banner
  echo "====================================="
  echo "  macOS Dotfiles Installation Script"
  echo "====================================="
  echo

  # Basic system checks
  check_system_compatibility

  # Update system
  install_updates

  # Install Homebrew
  install_homebrew

  # Install package managers and packages
  install_homebrew_packages

  # Configure zsh
  configure_zsh

  # Install binary scripts
  install_binary_scripts

  # Install configuration files
  install_config_files

  # Configure git
  configure_git

  # Completion message
  echo
  echo "====================================="
  log_success "Dotfiles installation complete!"
  echo "====================================="
  echo "🎉 Please restart your terminal to see the changes!"

  if confirm "Would you like to restart your terminal now?"; then
    log_info "Please close and reopen your terminal manually."
  fi
}

# Execute main function
main "$@"

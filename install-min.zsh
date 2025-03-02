#!/usr/bin/env zsh
# =============================================================================
#
#  Minimal Dotfiles Installer Script for macOS
#
#  This script only installs configuration files and sets up Antidote.
#
# =============================================================================

set -e # Exit immediately if a command exits with a non-zero status
set -u # Treat unset variables as an error

# =============================================================================
# CONFIGURATION
# =============================================================================

# Path to your dotfiles directory (assumed to be the current working directory)
DOTFILES_DIR="$(pwd)"

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

# =============================================================================
# CORE FUNCTIONS
# =============================================================================

check_system_compatibility() {
  log_info "Checking system compatibility..."
  if [[ "$(uname)" != "Darwin" ]]; then
    log_error "This script is only designed for macOS. Aborting."
    exit 1
  fi
  log_success "System compatibility check passed."
}

install_homebrew() {
  log_info "Installing Homebrew..."

  # Check if Homebrew is already installed
  if command -v brew &>/dev/null; then
    log_info "Homebrew is already installed. Updating..."
    brew update || {
      log_warning "Failed to update Homebrew."
    }
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

  # Install zsh and antidote via Homebrew
  log_info "Installing zsh and antidote via Homebrew..."
  brew install zsh antidote || {
    log_error "Failed to install zsh and antidote via Homebrew."
    return 1
  }
}

configure_zsh() {
  log_info "Configuring Homebrew zsh..."

  # Get the path to Homebrew's zsh
  BREW_ZSH="$(brew --prefix)/bin/zsh"

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

install_config_files() {
  log_info "Installing configuration files..."

  # Create necessary directories
  mkdir -pv ~/.config/zsh/functions ~/.zsh.d || {
    log_warning "Failed to create zsh directories."
  }

  # Fix ZSH completion security issue
  log_info "Fixing ZSH completion security issues..."
  compaudit 2>/dev/null | xargs chmod g-w 2>/dev/null || {
    log_warning "No insecure directories found or permissions already correct."
  }

  # Backup existing .zshrc if it exists
  if [ -f "$HOME/.zshrc" ]; then
    log_info "Backing up existing .zshrc to .zshrc.dotbak"
    mv "$HOME/.zshrc" "$HOME/.zshrc.dotbak" || {
      log_warning "Failed to backup .zshrc."
    }
  fi

  # Copy .zshrc from the dotfiles repo; if missing, create a minimal one
  if [ -f "$DOTFILES_DIR/Nix/.zshrc" ]; then
    cp "$DOTFILES_DIR/Nix/.zshrc" "$HOME/.zshrc" || {
      log_warning "Failed to copy .zshrc from dotfiles."
    }
  else
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
EOF
  fi

  # Copy .zsh_plugins.txt; if missing, create a default one
  if [ -f "$DOTFILES_DIR/Nix/.zsh_plugins.txt" ]; then
    cp "$DOTFILES_DIR/Nix/.zsh_plugins.txt" "$HOME/.zsh_plugins.txt" || {
      log_warning "Failed to copy .zsh_plugins.txt from dotfiles."
    }
  else
    log_info "Creating default .zsh_plugins.txt..."
    cat >"$HOME/.zsh_plugins.txt" <<EOF
# Essential ZSH libraries (from mattmc3/zephyr)
mattmc3/zephyr path:lib/completion
mattmc3/zephyr path:lib/history
mattmc3/zephyr path:lib/key-bindings
mattmc3/zephyr path:lib/directories
mattmc3/zephyr path:lib/theme-and-appearance

# Standalone plugins
zsh-users/zsh-completions

# Shell Enhancements
zdharma-continuum/fast-syntax-highlighting kind:defer
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-autosuggestions
zsh-users/zsh-history-substring-search

# Auto-completion & navigation tools
marlonrichert/zsh-autocomplete
agkozak/zsh-z
EOF
  fi

  # Copy custom Zsh functions if they exist in the dotfiles repo
  if [ -d "$DOTFILES_DIR/Nix/functions" ]; then
    cp "$DOTFILES_DIR/Nix/functions/"*.zsh ~/.config/zsh/functions/ 2>/dev/null ||
      log_warning "Failed to copy custom Zsh functions."
  else
    log_warning "No functions directory found in dotfiles repo."
  fi

  log_success "Configuration files installed."
  log_info "Note: This is a minimal setup. For the full configuration with all plugins, use install.zsh instead."
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
  echo "====================================="
  echo "  Minimal macOS Dotfiles Installer"
  echo "====================================="
  echo

  check_system_compatibility
  install_homebrew
  configure_zsh
  install_config_files

  echo
  log_success "Installation complete! Please restart your terminal to see the changes."
}

# Execute main function
main "$@"

#!/usr/bin/env zsh
# =============================================================================
#
#  Dotfiles Installer Script for macOS
#
#  Author: AnalogCyan
#  License: Unlicense
#
# =============================================================================

set -e # Exit immediately if a command exits with a non-zero status
set -u # Treat unset variables as an error

# =============================================================================
# CONFIGURATION
# =============================================================================

# Homebrew package lists
BREW_TAPS=(
  "1password/tap"
  "epk/epk"
  "gromgit/fuse"
  "homebrew-ffmpeg/ffmpeg"
  "homebrew/cask"
  "homebrew/cask-fonts"
  "homebrew/services"
  "imxieyi/waifu2x"
  "nextfire/tap"
  "yt-dlp/taps"
)

BREW_FORMULAE=(
  "aria2"                                # High speed download utility with multi-protocol support
  "autoconf-archive"                     # Collection of macros for GNU Autoconf
  "automake"                             # Tool for generating GNU Standards-compliant Makefiles
  "bat"                                  # Cat clone with syntax highlighting and Git integration
  "btop"                                 # Resource monitor with CPU, memory, disk, and network usage
  "ccache"                               # Compiler cache for faster recompilation
  "cmake"                                # Cross-platform build system generator
  "colordiff"                            # Tool to colorize diff output
  "curl"                                 # Command line tool for transferring data with URLs
  "docutils"                             # Text processing system for converting plaintext to various formats
  "ffmpeg"                               # Play, record, convert, and stream audio and video
  "findutils"                            # Collection of GNU find, xargs, and locate
  "fortune"                              # Random quotations program
  "fzf"                                  # Command-line fuzzy finder
  "gawk"                                 # GNU awk utility
  "gh"                                   # GitHub's official command line tool
  "git"                                  # Distributed version control system
  "glow"                                 # Markdown reader for the terminal
  "gnu-sed"                              # GNU implementation of the sed utility
  "grep"                                 # GNU grep, egrep and fgrep
  "imagemagick"                          # Tools and libraries to manipulate images
  "lazygit"                              # Simple terminal UI for git commands
  "lolcat"                               # Rainbow coloring for text output
  "make"                                 # Utility for directing compilation
  "mas"                                  # Mac App Store command line interface
  "mosh"                                 # Mobile shell with roaming and intelligent local echo
  "ncdu"                                 # NCurses disk usage viewer
  "nerdfetch"                            # Clean system information tool
  "nextfire/tap/apple-music-discord-rpc" # Discord Rich Presence for Apple Music
  "ninja"                                # Small build system with focus on speed
  "node"                                 # JavaScript runtime environment
  "p7zip"                                # 7-Zip file archiver with high compression ratio
  "pandoc"                               # Universal document converter
  "prettier"                             # Code formatter for multiple languages
  "pv"                                   # Monitor the progress of data through a pipeline
  "rclone"                               # Rsync for cloud storage services
  "sherlock"                             # Hunt down social media accounts by username
  "starship"                             # Cross-shell prompt customization
  "thefuck"                              # Magnificent app which corrects your previous console command
  "toilet"                               # Display large colorful characters
  "tokei"                                # Display statistics about your code
  "viu"                                  # Terminal image viewer with Unicode support
  "wallpaper"                            # Manage the desktop wallpaper
  "watch"                                # Executes a program periodically, showing output fullscreen
  "wget"                                 # Internet file retriever
  "xz"                                   # General-purpose data compression tool
  "yt-dlp"                               # Fork of youtube-dl with additional features
  "zoxide"                               # Smarter cd command with learning abilities
)

BREW_CASKS=(
  "1password/tap/1password-cli"
  "crunch"
  "font-fira-code"
  "font-hack-nerd-font"
  "font-sf-mono-nerd-font"
  "powershell"
  "raycast"
  "etcher"
)

NPM_PACKAGES=(
  "prettier"
  "prettier-plugin-sh"
  "prettier-plugin-toml"
  "prettier-plugin-tailwind"
)

MAS_APPS=(
  "1219074514" # Curve (FKA Vectornator)
  "1320666476" # Wipr
  "1412716242" # Tally
  "1432182561" # Cascadea
  "1452453066" # Hidden Bar
  "1453273600" # Data Jar
  "1463298887" # Userscripts
  "1474276998" # HP Smart
  "1480068668" # Messenger
  "1482920575" # DuckDuckGo Privacy for Safari
  "1544743900" # Hush
  "1568262835" # Super Agent
  "1569813296" # 1Password for Safari
  "1573461917" # SponsorBlock for YouTube - Skip Sponsorships
  "1577761052" # Malwarebytes Browser Guard
  "1586435171" # Actions
  "1589151155" # Rerouter
  "1591303229" # Vinegar
  "1591366129" # Convusic
  "1592917505" # Noir
  "1594183810" # Shortery
  "1596706466" # Speediness
  "1601151613" # Baking Soda
  "409183694"  # Keynote
  "409201541"  # Pages
  "409203825"  # Numbers
  "417375580"  # BetterSnapTool
  "425424353"  # The Unarchiver
  "430255202"  # Mactracker
  "640199958"  # Developer
  "747648890"  # Telegram
  "803453959"  # Slack
  "899247664"  # TestFlight
  "937984704"  # Amphetamine
)

# Git configuration
GIT_USER_NAME="AnalogCyan"
GIT_USER_EMAIL="git@thayn.me"

# Paths
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

confirm() {
  read -r "REPLY?$1 (y/n) "
  case "$REPLY" in
  [yY][eE][sS] | [yY])
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

# =============================================================================
# INSTALLATION FUNCTIONS
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

  # Create iCloud & Downloads symlinks
  log_info "Creating symbolic links for iCloud and Downloads..."
  ln -sf "$HOME/Library/Mobile Documents/com~apple~CloudDocs/iCloud" "$HOME/iCloud" || {
    log_warning "Failed to create iCloud symlink."
  }
  ln -sf "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Downloads" "$HOME/Downloads" || {
    log_warning "Failed to create Downloads symlink."
  }

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

  # Install Homebrew taps
  log_info "Installing Homebrew taps..."
  for tap in "${BREW_TAPS[@]}"; do
    log_info "Tapping $tap..."
    brew tap "$tap" || {
      log_warning "Failed to tap $tap."
    }
  done

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

  # Install Nerd Fonts
  log_info "Installing Nerd Fonts..."
  nfonts=$(brew search "Nerd Font")
  for item in ${nfonts}; do
    if [[ "$item" == *"nerd-font"* ]]; then
      brew install --cask "$item" || {
        log_warning "Failed to install $item."
      }
    fi
  done

  log_success "Homebrew packages installed."
}

install_npm_packages() {
  log_info "Installing NPM packages..."

  # Check if npm is installed
  if ! command -v npm &>/dev/null; then
    log_error "npm is not installed. Skipping NPM packages."
    return 1
  fi

  # Install NPM packages
  for package in "${NPM_PACKAGES[@]}"; do
    log_info "Installing $package..."
    npm i -g "$package" || {
      log_warning "Failed to install $package."
    }
  done

  log_success "NPM packages installed."
}

install_mas_apps() {
  log_info "Installing Mac App Store applications..."

  # Check if mas is installed
  if ! command -v mas &>/dev/null; then
    log_error "mas is not installed. Skipping Mac App Store applications."
    return 1
  fi

  # Check if user is signed in to the App Store
  mas account &>/dev/null
  if [ $? -ne 0 ]; then
    log_warning "You are not signed in to the App Store. Please sign in and try again."
    return 1
  fi

  # Install Mac App Store applications
  for app in "${MAS_APPS[@]}"; do
    app_id=$(echo "$app" | awk '{print $1}')
    app_name=$(echo "$app" | awk '{for(i=2;i<=NF;++i)print $i}' | sed 's/# //')
    log_info "Installing $app_name..."
    mas install "$app_id" || {
      log_warning "Failed to install $app_name."
    }
  done

  log_success "Mac App Store applications installed."
}

# Helper function to install Antidote via git when Homebrew is unavailable
install_antidote_git() {
  log_info "Installing Antidote via git..."

  # Create Antidote directory
  mkdir -p ~/.antidote

  # Clone Antidote repository
  if [ ! -d "$HOME/.antidote" ]; then
    log_info "Cloning Antidote repository..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git ~/.antidote || {
      log_error "Failed to clone Antidote repository."
      return 1
    }
  else
    log_info "Antidote repository already exists. Updating..."
    (cd ~/.antidote && git pull)
  fi
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

  # Install Homebrew
  install_homebrew

  # Install binary scripts
  install_binary_scripts

  # Install configuration files
  install_config_files

  # Install package managers and packages
  install_homebrew_packages
  install_npm_packages
  install_mas_apps

  # Shell setup
  install_antidote_git

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

#!/usr/bin/env bash
# =============================================================================
#
#  Dotfiles Installer Script for Debian-based Systems
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

# Package lists - easy to update in the future
APT_PACKAGES=(
  "apt-transport-https"
  "bat"
  "ca-certificates"
  "curl"
  "ffmpeg"
  "fortune"
  "fzf"
  "g++"
  "gcc"
  "gh"
  "git"
  "gnupg"
  "htop"
  "lsb-release"
  "lolcat"
  "mosh"
  "mpv"
  "nodejs"
  "npm"
  "screen"
  "software-properties-common"
  "thefuck"
  "vim"
  "wget"
  "xz-utils"
  "yt-dlp"
  "zsh"
)

NPM_PACKAGES=(
  "prettier"
  "prettier-plugin-sh"
  "prettier-plugin-toml"
  "prettier-plugin-tailwind"
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
  read -p "$1 (y/n) " response
  case "$response" in
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

  if ! command -v apt &>/dev/null; then
    log_error "This script was only designed for Debian-based systems. Aborting."
    exit 1
  fi

  log_success "System compatibility check passed."
}

is_server_installation() {
  if confirm "Is this a server installation?"; then
    IS_SERVER=true
    log_info "Configuring as server installation."
    return 0
  else
    IS_SERVER=false
    log_info "Configuring as desktop installation."
    return 1
  fi
}

install_updates() {
  log_info "Ensuring system is up-to-date..."

  sudo apt update --fix-missing || {
    log_error "Failed to update package lists."
    exit 1
  }

  sudo apt upgrade -y || {
    log_warning "Some packages could not be upgraded."
  }

  sudo apt autoremove -y
  sudo apt --fix-broken install -y

  log_success "System updated successfully."
}

install_apt_packages() {
  log_info "Installing APT packages..."

  echo "Installing: ${APT_PACKAGES[*]}..."
  sudo apt install -y "${APT_PACKAGES[@]}" || {
    log_warning "Some APT packages failed to install."
  }

  # Fix issue with apt version of bat
  if command -v batcat &>/dev/null; then
    sudo mkdir -p ~/.local/bin
    sudo ln -sf /usr/bin/batcat ~/.local/bin/bat
    log_success "Created bat symlink for batcat."
  fi

  log_success "APT packages installed."
}

install_logo_ls() {
  log_info "Installing logo-ls..."

  # Determine system architecture
  ARCH=$(dpkg --print-architecture)

  # Map architecture to logo-ls naming convention
  case "$ARCH" in
  amd64) ARCH="amd64" ;;
  i386) ARCH="i386" ;;
  arm64) ARCH="arm64" ;;
  armhf) ARCH="armV6" ;; # Adjust if needed based on actual naming conventions
  *)
    log_error "Unsupported architecture: $ARCH"
    return 1
    ;;
  esac

  # Fetch latest release tag
  LATEST_TAG=$(wget -qO- "https://api.github.com/repos/Yash-Handa/logo-ls/releases/latest" | grep -oP '"tag_name": "\K(.*?)(?=")')
  if [ -z "$LATEST_TAG" ]; then
    log_error "Failed to fetch latest release."
    return 1
  fi

  # Construct download URL
  DEB_URL="https://github.com/Yash-Handa/logo-ls/releases/download/${LATEST_TAG}/logo-ls_${ARCH}.deb"

  # Download and install
  wget -q "$DEB_URL" -O "logo-ls_${ARCH}.deb" || {
    log_error "Failed to download logo-ls package."
    return 1
  }

  sudo dpkg -i "logo-ls_${ARCH}.deb"
  rm -f "logo-ls_${ARCH}.deb"

  log_success "logo-ls installed successfully."
}

install_1password_cli() {
  log_info "Installing 1Password CLI..."

  # Add the key
  curl -sS https://downloads.1password.com/linux/keys/1password.asc |
    sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg || {
    log_error "Failed to add 1Password GPG key."
    return 1
  }

  # Add the repository
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" |
    sudo tee /etc/apt/sources.list.d/1password.list >/dev/null

  # Add debsig policy
  sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
  curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol |
    sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol >/dev/null

  # Add debsig keyring
  sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
  curl -sS https://downloads.1password.com/linux/keys/1password.asc |
    sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

  # Install the package
  sudo apt update && sudo apt install -y 1password-cli

  log_success "1Password CLI installed."
}

#install_powershell() {
#  log_info "Installing PowerShell..."
#
#  # Get the version of Debian
#  source /etc/os-release
#
#  # Download the Microsoft repository GPG keys
#  wget -q "https://packages.microsoft.com/config/debian/$VERSION_ID/packages-microsoft-prod.deb" || {
#    log_error "Failed to download PowerShell package."
#    return 1
#  }
#
#  # Register the Microsoft repository GPG keys
#  sudo dpkg -i packages-microsoft-prod.deb
#
#  # Delete the Microsoft repository GPG keys file
#  rm packages-microsoft-prod.deb
#
#  # Update package lists after adding Microsoft repository
#  sudo apt update
#
#  # Install PowerShell
#  sudo apt install -y powershell || {
#    log_error "Failed to install PowerShell."
#    return 1
#  }
#
#  log_success "PowerShell installed."
#}

install_starship() {
  log_info "Installing Starship prompt..."

  # Create .config directory if it doesn't exist
  mkdir -p ~/.config

  if ! command -v starship &>/dev/null; then
    log_info "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y || {
      log_error "Failed to install Starship."
      return 1
    }
  else
    log_info "Starship is already installed. Let's make sure it's up to date..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi

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

  log_success "Starship prompt installed and configured."
}

install_npm_packages() {
  log_info "Installing NPM packages..."

  if ! command -v npm &>/dev/null; then
    log_error "npm is not installed. Skipping NPM packages."
    return 1
  fi

  for package in "${NPM_PACKAGES[@]}"; do
    log_info "Installing npm package: $package"
    sudo npm install -g "$package" || {
      log_warning "Failed to install npm package: $package"
    }
  done

  log_success "NPM packages installed."
}

change_default_shell() {
  log_info "Changing default shell to zsh..."

  if ! command -v zsh &>/dev/null; then
    log_error "zsh is not installed. Cannot change default shell."
    return 1
  fi

  chsh -s "$(which zsh)" || {
    log_error "Failed to change default shell."
    return 1
  }

  log_success "Default shell changed to zsh."
}

install_antidote() {
  log_info "Installing Antidote for ZSH plugin management..."

  # Always use git installation method on Linux
  install_antidote_git

  # Copy .zsh_plugins.txt from dotfiles repo to home directory
  if [ -f "$DOTFILES_DIR/Nix/.zsh_plugins.txt" ]; then
    cp "$DOTFILES_DIR/Nix/.zsh_plugins.txt" ~/.zsh_plugins.txt || {
      log_warning "Failed to copy .zsh_plugins.txt"
    }
    log_success "Copied .zsh_plugins.txt to home directory"
  else
    log_info "Creating default .zsh_plugins.txt..."
    cat >~/.zsh_plugins.txt <<EOF
# Essential ZSH plugins with Antidote

# Core ZSH libraries
mattmc3/zephyr path:lib/completion.zsh
mattmc3/zephyr path:lib/history.zsh
mattmc3/zephyr path:lib/key-bindings.zsh
mattmc3/zephyr path:lib/directories.zsh
mattmc3/zephyr path:lib/theme-and-appearance.zsh

# Essential plugins
zsh-users/zsh-completions
zsh-users/zsh-autosuggestions
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-history-substring-search
robbyrussell/oh-my-zsh path:plugins/git
robbyrussell/oh-my-zsh path:plugins/sudo
robbyrussell/oh-my-zsh path:plugins/command-not-found
agkozak/zsh-z
robbyrussell/oh-my-zsh path:plugins/extract
EOF
  fi

  # Install and configure fzf
  if command -v fzf &>/dev/null; then
    log_info "Setting up fzf shell extensions..."
    # Check if fzf shell extensions aren't already installed
    if [ ! -f "$HOME/.fzf.zsh" ]; then
      log_info "Installing fzf shell extensions..."
      git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" 2>/dev/null || {
        log_info "fzf shell repo already exists, updating..."
        (cd "$HOME/.fzf" && git pull)
      }
      # Install just the shell extensions without reinstalling the binary
      "$HOME/.fzf/install" --key-bindings --completion --no-update-rc || {
        log_warning "Failed to install fzf shell extensions."
      }
    else
      log_info "fzf shell extensions are already installed."
    fi
  else
    log_warning "fzf is not installed through apt. Check APT_PACKAGES array."
  fi

  log_success "Antidote and ZSH plugins configured."
}

# Helper function to install Antidote via git
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

install_zsh_configs_and_functions() {
  log_info "Installing zsh config and functions..."

  # Create necessary directories
  mkdir -pv ~/.config/zsh/functions || {
    log_warning "Failed to create zsh functions directory."
  }

  # Backup existing zshrc if it exists
  if [ -f "$HOME/.zshrc" ]; then
    log_info "Backing up existing .zshrc to .zshrc.dotbak"
    mv "$HOME/.zshrc" "$HOME/.zshrc.dotbak"
  fi

  # Copy configuration files
  if [ -f "$DOTFILES_DIR/Nix/.zshrc" ]; then
    cp "$DOTFILES_DIR/Nix/.zshrc" "$HOME/.zshrc"
    log_success "Installed .zshrc"
  else
    log_error "Could not find .zshrc in the dotfiles repo."
    # Create a minimal .zshrc file
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
#  Plugin Management (Antidote)
# =============================================================================

# Initialize Antidote
source "\$HOME/.antidote/antidote.zsh"
antidote load ~/.zsh_plugins.txt

# =============================================================================
#  Shell Configuration
# =============================================================================

# Set completion options
autoload -Uz compinit
compinit -d ~/.zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt histignorealldups
setopt histignorespace

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

# =============================================================================
#  Custom Functions
# =============================================================================

# Load all custom functions
for func in \$HOME/.config/zsh/functions/*.zsh; do
  source "\$func"
done

# Display greeting on shell start
zsh_greeting
EOF
  fi

  # Copy custom functions
  if [ -d "$DOTFILES_DIR/Nix/functions" ]; then
    cp "$DOTFILES_DIR/Nix/functions/"*.zsh ~/.config/zsh/functions/ || {
      log_warning "Failed to copy zsh functions."
    }
    log_success "Installed zsh functions"
  else
    log_error "Could not find functions directory in the dotfiles repo."
  fi

  log_success "ZSH configuration and functions installed."
}

install_bin_scripts_and_shortcuts() {
  log_info "Installing bin scripts and shortcuts..."

  # Create bin directory if it doesn't exist
  mkdir -pv ~/bin/apps/pfetch/

  # Copy bin files if they exist
  if [ -d "$DOTFILES_DIR/Nix/bin" ]; then
    cp -r "$DOTFILES_DIR/Nix/bin/"* ~/bin/ 2>/dev/null || {
      log_warning "No bin files to copy."
    }
  fi

  # Install pfetch
  log_info "Installing pfetch..."
  if [ ! -d "$HOME/bin/apps/pfetch/.git" ]; then
    git clone https://github.com/dylanaraps/pfetch.git ~/bin/apps/pfetch/ || {
      log_error "Failed to clone pfetch."
    }
  else
    (cd ~/bin/apps/pfetch && git pull)
  fi

  # Make sure scripts are executable
  find ~/bin -type f -exec chmod +x {} \; 2>/dev/null

  log_success "Bin scripts and shortcuts installed."
}

server_config() {
  log_info "Installing server-specific configs..."

  # Install iTerm2 shell integration
  log_info "Installing iTerm2 shell integration..."
  curl -L https://iterm2.com/shell_integration/install_shell_integration.sh | bash || {
    log_warning "Failed to install iTerm2 shell integration."
  }

  # Install NextDNS
  log_info "Installing NextDNS..."
  sh -c "$(curl -sL https://nextdns.io/install)" || {
    log_warning "Failed to install NextDNS."
  }

  # Install Plex Media Server
  log_info "Installing Plex Media Server..."
  wget -q "https://downloads.plex.tv/plex-media-server-new/1.30.0.6486-629d58034/debian/plexmediaserver_1.30.0.6486-629d58034_amd64.deb" || {
    log_warning "Failed to download Plex Media Server."
  }

  sudo dpkg -i plexmediaserver_1.30.0.6486-629d58034_amd64.deb || {
    log_warning "Failed to install Plex Media Server."
  }

  rm -f plexmediaserver_1.30.0.6486-629d58034_amd64.deb

  install_docker

  log_success "Server-specific configs installed."
}

install_docker() {
  log_info "Installing Docker..."

  # Remove old Docker installs
  log_info "Removing old Docker installations..."
  sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
  sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || true
  sudo rm -rf /var/lib/docker /var/lib/containerd 2>/dev/null || true

  # Set up the Docker repository
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg || {
    log_error "Failed to add Docker GPG key."
    return 1
  }

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt update

  # Install Docker and related packages
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose || {
    log_error "Failed to install Docker."
    return 1
  }

  # Add the current user to the Docker group
  sudo usermod -aG docker "$USER"

  # Enable and start Docker
  sudo systemctl enable docker
  sudo systemctl start docker

  log_success "Docker installed successfully."
}

configure_git() {
  log_info "Configuring git..."

  if ! command -v git &>/dev/null; then
    log_error "Git is not installed. Cannot configure git."
    return 1
  fi

  # Choose appropriate editor based on environment
  local editor
  if [ -z "${DISPLAY:-}" ]; then
    # No graphical interface detected, default to vim
    editor="vim"
  else
    # A graphical interface is available, default to vscode
    if command -v code &>/dev/null; then
      editor="code --wait -n"
    else
      editor="vim" # Default to vim if VSCode is not installed
    fi
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
  echo "  Dotfiles Installation Script"
  echo "====================================="
  echo

  local IS_SERVER=false

  # Check for root
  if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root or with sudo."
    exit 1
  fi

  # Basic system checks
  check_system_compatibility

  # Determine if this is a server installation
  if is_server_installation; then
    IS_SERVER=true
  fi

  # Update system first
  install_updates

  # Install base packages
  install_apt_packages
  install_logo_ls
  install_1password_cli
  #install_powershell
  install_npm_packages
  install_starship

  # Shell setup
  change_default_shell
  install_antidote
  install_zsh_configs_and_functions

  # Scripts and utilities
  install_bin_scripts_and_shortcuts

  # Server specific configs
  if [ "$IS_SERVER" = true ]; then
    server_config
  fi

  # Configure git
  configure_git

  # Completion message
  echo
  echo "====================================="
  log_success "Dotfiles installation complete!"
  echo "====================================="

  if confirm "Would you like to reboot now to complete the setup?"; then
    log_info "Rebooting system..."
    sudo reboot
  else
    log_info "No reboot selected. Some changes may require a restart to take effect."
  fi
}

# Execute main function
main "$@"

#!/usr/bin/env bash
# An extremely basic script for installing my dotfiles on Linux.

# Define functions for different installation steps
check_system_compatibility() {
  if ! command -v apt &>/dev/null; then
    echo "Error: this script was only designed for debian-based systems. Aborting."
    exit 1
  fi
}

check_system_type() {
  read -p "Is this a server? (y/n) " server
  if [[ $server == "y" ]]; then
    return "server"
  else
    echo "📱 Skipping server-specific configs..."
  fi
}

install_updates() {
  echo "⏫ Ensuring system is up-to-date..."
  sudo apt update --fix-missing && sudo apt upgrade && sudo apt autoremove && sudo apt --fix-broken install
}

install_software() {
  echo
  echo "📦 Installing packages..."

  local packages=(
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
    "mosh"
    "mpv"
    "nodejs"
    "npm"
    "screen"
    "thefuck"
    "vim"
    "xz-utils"
    "yt-dlp"
    "zsh"
  )

  echo "Installing: ${packages[*]}..."
  sudo apt install ${packages[*]}

  # Fix issue with apt version of bat
  sudo mkdir -p ~/.local/bin
  sudo ln -s /usr/bin/batcat ~/.local/bin/bat

  # Install logo-ls
  wget -q "https://github.com/Yash-Handa/logo-ls/releases/download/v1.3.7/logo-ls_amd64.deb"
  sudo dpkg -i logo-ls_amd64.deb

  # Install 1Password CLI
  curl -sS https://downloads.1password.com/linux/keys/1password.asc |
    sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" |
    sudo tee /etc/apt/sources.list.d/1password.list
  sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
  curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol |
    sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
  sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
  curl -sS https://downloads.1password.com/linux/keys/1password.asc |
    sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
  sudo apt update && sudo apt install 1password-cli

  # Install PowerShell
  wget -q "https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb"
  sudo dpkg -i packages-microsoft-prod.deb
  sudo apt update
  sudo apt install -y powershell

  # Install node packages.
  npm=(
    "prettier"
    "prettier-plugin-sh"
    "prettier-plugin-toml"
    "prettier-plugin-tailwind"
  )
  for i in "${npm[@]}"; do
    sudo npm i -g "$i"
  done
}

change_default_shell() {
  echo "Changing shell to zsh..."
  chsh -s $(which zsh)
}

install_oh_my_zsh() {
  local ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

  echo
  echo "🕶️  Installing Oh-My-Zsh and plugins..."

  # Install Oh-My-Zsh
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  # Install Fuzzy Finder
  "$(brew --prefix)/opt/fzf/install"

  # Define an array for plugins git repos
  plugins=(
    "https://github.com/zsh-users/zsh-history-substring-search.git"
    "https://github.com/zsh-users/zsh-completions.git"
    "https://github.com/MichaelAquilina/zsh-you-should-use.git"
    "https://github.com/zsh-users/zsh-syntax-highlighting.git"
    "https://github.com/zsh-users/zsh-autosuggestions.git"
  )

  # Clone each plugin
  for plugin in "${plugins[@]}"; do
    git clone "${plugin}" "${ZSH_CUSTOM}/plugins/$(basename -s .git "${plugin}")"
  done
}

install_zsh_configs_and_functions() {
  echo "Installing zsh config and functions..."

  # Ensure the omz custom directory exists
  mkdir -pv ~/.oh-my-zsh/custom/

  # Backup & import zsh config
  mv ~/.zshrc ~/.zshrc.dotbak
  cp ./macOS/Users/cyan/.zshrc ~/.zshrc
  cp ./macOS/Users/cyan/.oh-my-zsh/custom/*.zsh ~/.oh-my-zsh/custom/
}

install_bin_scripts_and_shortcuts() {
  echo "Installing bin scripts and shortcuts..."
  mkdir -pv ~/bin/apps/pfetch/
  cp -r ./Linux/home/cyan/bin/* ~/bin/

  echo "Installing pfetch..."
  git clone https://github.com/dylanaraps/pfetch.git ~/bin/apps/pfetch/
  sudo chmod +x ~/bin/*
}

server_config() {
  echo "🖥️  Installing server-specific configs..."

  # Install iTerm2 shell integration
  curl -L https://iterm2.com/shell_integration/install_shell_integration.sh | bash

  # Install NextDNS
  sh -c "$(curl -sL https://nextdns.io/install)"

  # Install Plex
  wget -q "https://downloads.plex.tv/plex-media-server-new/1.30.0.6486-629d58034/debian/plexmediaserver_1.30.0.6486-629d58034_amd64.deb"
  sudo dpkg -i plexmediaserver_1.30.0.6486-629d58034_amd64.deb

  # Remove old Docker install(s)
  sudo apt-get remove docker docker-engine docker.io containerd runc
  sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo rm -rf /var/lib/docker
  sudo rm -rf /var/lib/containerd

  # Install Docker
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose
  sudo usermod -aG docker $USER
  sudo systemctl enable docker
  sudo systemctl start docker
}

configure_git() {
  local editor
  if [ -z "$DISPLAY" ]; then
    # No graphical interface detected, default to vim
    editor="vim"
  else
    # A graphical interface is available, default to vscode
    editor="code --wait -n"
  fi

  echo "Configuring git..."
  git config --global core.editor "$editor"
  git config --global user.name "AnalogCyan"
  git config --global user.email "git@thayn.me"
}

# Main function to call all defined functions.
main() {
  check_system_compatibility
  install_updates
  install_software
  change_default_shell
  install_oh_my_zsh
  install_zsh_configs_and_functions
  install_bin_scripts_and_shortcuts

  if check_system_type == "server"; then
    server_config
  fi

  if command -v git &>/dev/null; then
    configure_git
  fi

  read -p "🎉 Dotfiles installed! Press Enter to reboot now." </dev/tty
  sudo reboot
}
main

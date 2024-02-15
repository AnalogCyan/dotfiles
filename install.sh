#!/usr/bin/env bash

# Define functions for different installation steps
check_system_compatibility() {
  if ! command -v apt &>/dev/null; then
    echo "Error: this script was only designed for debian-based systems. Aborting."
    exit 1
  fi
}

install_updates() {
  echo "Ensuring system is up-to-date..."
  sudo apt update --fix-missing && sudo apt upgrade && sudo apt autoremove && sudo apt --fix-broken install
}

install_software() {
  local packages=(
    "gcc"
    "g++"
    "git"
    "vim"
    "htop"
    "zsh"
    "fortune"
    "mosh"
    "screen"
  )

  echo "Installing: ${packages[*]}..."
  sudo apt install ${packages[*]}
}

change_default_shell() {
  echo "Changing shell to zsh..."
  chsh -s $(which zsh)
}

install_ohmyzsh() {
  echo "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_zsh_configs_and_functions() {
  echo "Installing zsh config and functions..."

  if [[ -e ~/.oh-my-zsh ]]; then
    # create custom directories in the "~/.oh-my-zsh/custom" directory for functions if they do not exist
    [[ ! -e ~/.oh-my-zsh/custom/functions ]] && mkdir ~/.oh-my-zsh/custom/functions

    # copy your functions there
    cp ./Linux/home/cyan/.oh-my-zsh/custom/functions/*.zsh ~/.oh-my-zsh/custom/functions/
  fi

  # Copy zsh config after oh-my-zsh installation, to prevent overwriting by oh-my-zsh
  cp ./Linux/home/cyan/.zshrc ~/
}

install_bin_scripts_and_shortcuts() {
  echo "Installing bin scripts and shortcuts..."
  mkdir -pv ~/bin/apps/
  cp -r ./Linux/home/cyan/bin/* ~/bin/

  mkdir -pv ~/.local/share/applications/
  cp -r ./Linux/home/cyan/.local/share/applications/* ~/.local/share/applications/

  echo "Installing pfetch..."
  git clone https://github.com/dylanaraps/pfetch.git ~/bin/apps/pfetch/
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
  install_ohmyzsh
  install_zsh_configs_and_functions
  install_bin_scripts_and_shortcuts

  if command -v git &>/dev/null; then
    configure_git
  fi

  echo "Dotfiles installed! Please restart your terminal to see the changes. You may need to log out and log back in to see changes in the default shell."
}
main

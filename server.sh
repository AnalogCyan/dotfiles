#!/usr/bin/env bash
# An extremely basic script for configuring my home server.

# Install updates.
sudo apt update --fix-missing
sudo apt upgrade
sudo apt autoremove
sudo apt --fix-broken install

# Install packages.
pkgs=(
  "bat"
  "ca-certificates"
  "curl"
  "docker"
  "ffmpeg"
  "fortune"
  "g++"
  "gcc"
  "git"
  "gnupg"
  "htop"
  "lsb-release"
  "mosh"
  "screen"
  "vim"
  "zsh"
  "fzf"
  "gh"
  "mpv"
  "thefuck"
  "xz-utils"
  "yt-dlp"
)
for i in "${pkgs[@]}"; do
  sudo apt -y install "$i"
done

# Fix issue with apt version of bat
sudo mkdir -p ~/.local/bin
sudo ln -s /usr/bin/batcat ~/.local/bin/bat

# Install 1Password CLI
curl -sS https://downloads.1password.com/linux/keys/1password.asc \
  | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" \
  | sudo tee /etc/apt/sources.list.d/1password.list
sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol \
  | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/keys/1password.asc \
  | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
sudo apt update && sudo apt install 1password-cli

# Install PowerShell
sudo apt-get install -y wget apt-transport-https software-properties-common
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell

# Install node packages.
npm=(
  "prettier"
  "prettier-plugin-sh"
  "prettier-plugin-toml"
  "prettier-plugin-tailwind"
)
for i in "${npm[@]}"; do
  npm i -g "$i"
done

# Install ~/bin scripts/apps
mkdir -pv ~/bin/apps/pfetch/
cp ./Linux/home/cyan/bin/* ~/bin/
git clone https://github.com/dylanaraps/pfetch.git ~/bin/apps/pfetch/

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Backup & import .zshrc config
mkdir -pv ~/.oh-my-zsh/custom/
mv ~/.zshrc ~/.zshrc.dotbak
cp ./macOS/Users/cyan/.zshrc ~/.zshrc
cp ./macOS/Users/cyan/.oh-my-zsh/custom/* "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"

# Install additional zsh plugins.
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Install iTerm2 shell integration
curl -L https://iterm2.com/shell_integration/install_shell_integration.sh | bash

# Install NextDNS
sh -c "$(curl -sL https://nextdns.io/install)"

# Remove old Docker install(s)
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# Install Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.gpg
sudo apt update
sudo apt -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Done!
echo "Dotfiles installed! Restart your terminal to see the changes!"

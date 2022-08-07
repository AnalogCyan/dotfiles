#!/usr/bin/env bash
# An extremely basic script for installing my dotfiles on macOS.

# Copy/install ~/bin scripts/apps
mkdir ~/bin/
cp ./bin/* ~/bin/
mkdir ~/bin/apps/
git clone https://github.com/dylanaraps/pfetch.git ~/bin/apps/

# Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Backup & import .zshrc config
mv ~/.zshrc ~/.zshrc.dotbak
cp ./.zshrc ~/.zshrc

# ln Minecraft dir > iCloud
ln -s "/Users/cyan/Library/Mobile Documents/com~apple~CloudDocs/Minecraft/Install" "/Users/cyan/Library/Application Support/minecraft"

# Install additonal deps
brew install --cask 1password/tap/1password-cli
brew install yt-dlp mosh fortune gh fzf
$(brew --prefix)/opt/fzf/install

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Done!
echo "Dotfiles installed! Restart your terminal to see the changes!"

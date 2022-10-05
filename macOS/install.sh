#!/usr/bin/env bash
# An extremely basic script for installing my dotfiles on macOS.

# Copy/install ~/bin scripts/apps
mkdir -pv ~/bin/apps/
cp ./home/cyan/bin/* ~/bin/
git clone https://github.com/dylanaraps/pfetch.git ~/bin/apps/

# Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Backup & import .zshrc config
mkdir -pv ~/.oh-my-zsh/custom/
mv ~/.zshrc ~/.zshrc.dotbak
cp ./home/cyan/.zshrc ~/.zshrc
cp ./home/cyan/.oh-my-zsh/custom/* ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

# ln Minecraft dir > iCloud
ln -s "~/Library/Mobile Documents/com~apple~CloudDocs/Minecraft/Install" "~/Library/Application Support/minecraft"

# Install additonal deps/apps
taps=(
    "homebrew/cask-fonts"
)
formulae=(
    "bat"
    "ffmpeg"
    "fortune"
    "fzf"
    "gh"
    "mosh"
    "xz"
    "yt-dlp"
)
casks=(
    "1password/tap/1password-cli"
    "crunch"
    "font-fira-code"
    "font-sf-mono-nerd-font"
    "powershell"
    "raycast"
)
for i in ${taps[@]}; do
    brew tap $i
done
for i in ${formulae[@]}; do
    brew install $i
done
for i in ${casks[@]}; do
    brew install --cask $i
done
$(brew --prefix)/opt/fzf/install

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Done!
echo "Dotfiles installed! Restart your terminal to see the changes!"

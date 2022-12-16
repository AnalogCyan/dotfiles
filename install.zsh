#!/usr/bin/env zsh
# An extremely basic script for installing my dotfiles on macOS.

# Copy/install ~/bin scripts/apps
mkdir -pv ~/bin/apps/pfetch/
cp ./macOS/Users/cyan/bin/* ~/bin/
git clone https://github.com/dylanaraps/pfetch.git ~/bin/apps/pfetch/

# Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#- Run these three commands in your terminal to add Homebrew to your PATH:
#    echo '# Set PATH, MANPATH, etc., for Homebrew.' >> /Users/cyan/.zprofile
#    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/cyan/.zprofile
#    eval "$(/opt/homebrew/bin/brew shellenv)"

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Backup & import .zshrc config
mkdir -pv ~/.oh-my-zsh/custom/
mv ~/.zshrc ~/.zshrc.dotbak
cp ./macOS/Users/cyan/.zshrc ~/.zshrc
cp ./macOS/Users/cyan/.oh-my-zsh/custom/* "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"

# ln Downloads dir > icloud
ln -s "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Downloads" "$HOME/Downloads"

# ln Minecraft dir > iCloud
ln -s "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Minecraft/Install" "$HOME/Library/Application Support/minecraft"

# Install additonal deps/apps
taps=(
  "homebrew/cask"
  "homebrew/cask-fonts"
  "epk/epk"
)
formulae=(
  "bat"
  "ffmpeg"
  "fortune"
  "fzf"
  "gh"
  "iterm2"
  "mas"
  "mosh"
  "mpv"
  "node"
  "thefuck"
  "xz"
  "yt-dlp"
)
casks=(
  "1password/tap/1password-cli"
  "crunch"
  "font-fira-code"
  "font-hack-nerd-font"
  "font-sf-mono-nerd-font"
  "powershell"
  "raycast"
  "transmission"
  "windscribe"
  "etcher"
)
nfonts=$(brew search "Nerd Font")
npm=(
  "prettier"
  "prettier-plugin-sh"
  "prettier-plugin-toml"
  "prettier-plugin-tailwind"
)
apps=(
  "1067646949" # New Terminal Here
  "1085114709" # Parallels Desktop
  "1219074514" # Vectornator
  "1320666476" # Wipr
  "1339170533" # CleanMyMac-MAS
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
for i in "${taps[@]}"; do
  brew tap "$i"
done
for i in "${formulae[@]}"; do
  brew install "$i"
done
for i in "${casks[@]}"; do
  brew install --cask "$i"
done
for item in {$nfonts}; do
  if [[ "$item" == *"nerd-font"* ]]; then
    brew install --cask $item
  fi
done
for i in "${npm[@]}"; do
  npm i -g "$i"
done
for i in "${apps[@]}"; do
  mas install "$i"
done

$(brew --prefix)/opt/fzf/install
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Install iTerm2 shell integration
curl -L https://iterm2.com/shell_integration/install_shell_integration.sh | bash

# Done!
echo "Dotfiles installed! Restart your terminal to see the changes!"

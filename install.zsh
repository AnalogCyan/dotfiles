#!/usr/bin/env zsh
# An extremely basic script for installing my dotfiles on macOS.

# Define functions for different installation steps

install_apps() {
    echo
    echo "⭐️ Installing required applications..."

    # Copy/install ~/bin scripts/apps
    mkdir -pv ~/bin/apps/pfetch/
    cp ./macOS/Users/cyan/bin/* ~/bin/
    git clone https://github.com/dylanaraps/pfetch.git ~/bin/apps/pfetch/

    # Install homebrew
    echo
    echo "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo '# Set PATH, MANPATH, etc., for Homebrew.' >>/Users/cyan/.zprofile
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>/Users/cyan/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
}

install_config_files() {
    echo
    echo "⚙️  Installing configuration files..."

    # Backup & import .zshrc config
    mkdir -pv ~/.oh-my-zsh/custom/
    mv ~/.zshrc ~/.zshrc.dotbak
    cp ./macOS/Users/cyan/.zshrc ~/.zshrc
    cp ./macOS/Users/cyan/.oh-my-zsh/custom/* "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"

    # ln iCloud & Downloads in home directory
    ln -s "$HOME/Library/Mobile Documents/com~apple~CloudDocs/iCloud" "$HOME/iCloud"
    ln -s "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Downloads" "$HOME/Downloads"
}

install_package_managers() {
    echo
    echo "📦 Installing packages..."

    # Install additional deps/apps
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
      "prettier"
      "thefuck"
      "xz"
      "yt-dlp"
      "nodejs"
    )

    casks=(
      "1password/tap/1password-cli"
      "crunch"
      "font-fira-code"
      "font-hack-nerd-font"
      "font-sf-mono-nerd-font"
      "powershell"
      "raycast"
      "etcher"
    )

    for i in "${taps[@]}"; do brew tap "$i"; done
    for i in "${formulae[@]}"; do brew install "$i"; done
    for i in "${casks[@]}"; do brew install --cask "$i"; done

    nfonts=$(brew search "Nerd Font")
    for item in {$nfonts}; do
      if [[ "$item" == *" "nerd-font"* ]]; then
        brew install --cask $item
      fi
    done

    npm=(
      "prettier"
      "prettier-plugin-sh"
      "prettier-plugin-toml"
      "prettier-plugin-tailwind"
    )

    for i in "${npm[@]}"; do npm i -g "$i"; done
}

install_mas_apps(){
    apps=(
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

    echo "🎁 Installing MAS apps..."
    for i in "${apps[@]}"; do mas install "$i"; done
}

install_oh_my_zsh() {
    echo
    echo "🕶️  Installing Oh-My-Zsh and plugins..."

    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    $(brew --prefix)/opt/fzf/install
    git clone https://github.com/MichaelAquilina/zsh-you-should-use.git $ZSH_CUSTOM/plugins/you-should-use
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

    echo "source $ZSH_CUSTOM/plugins/you-should-use/you-should-use.plugin.zsh" >> ~/.zshrc
    echo "source $ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
    echo "source $ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
}

# Main function to call all defined functions.
main(){
    install_apps
    install_config_files
    install_package_managers
    install_mas_apps
    install_oh_my_zsh
    echo "🎉 Dotfiles installed! Restart your terminal to see the changes!"
}
main

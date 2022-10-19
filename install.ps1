#!/usr/bin/env pwsh

function InstallLinux {
    if (-Not $(Get-Command "apt")) {
        Write-Error "This script was only designed for debian-based systems. Aborting."
        exit
    }
}

function InstallMacOS {
    New-Item -Path "~/bin/apps/pfetch/" -ItemType Directory -Force
    Copy-Item -Path "./macOS/Users/cyan/bin/" -Destination "~/bin/" -Force -Recurse
    git clone "https://github.com/dylanaraps/pfetch.git" "~/bin/apps/pfetch/"

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    New-Item -Path "~/.oh-my-zsh/custom/" -ItemType Directory -Force
    Move-Item -Path "~/.zshrc" -Destination "~/.zshrc.dotbak" -Force
    Copy-Item -Path "./macOS/Users/cyan/.zshrc" "~/.zshrc" -Force
    Copy-Item -Path "./macOS/Users/cyan/.oh-my-zsh/custom/" -Destination "$(zsh -c 'echo ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}')" -Force -Recurse

    ln -s "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Minecraft/Install" "$HOME/Library/Application Support/minecraft"

    $taps = @()
    $formulae = @()
    $casks = @()
    $npm = @()
    $apps = @()
    ForEach ($i in $taps) { brew tap "$i" }
    ForEach ($i in $formulae) { brew install "$i" }
    ForEach ($i in $casks) { brew install --cask "$i" }
    ForEach ($i in $npm) { npm i -g "$i" }
    ForEach ($i in $apps) { mas install "$i" }

    zsh -c "`$(brew --prefix)/opt/fzf/install"
    zsh -c 'git clone "https://github.com/zsh-users/zsh-autosuggestions" "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"'
    zsh -c 'git clone "https://github.com/zsh-users/zsh-completions" "${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions"'
    zsh -c 'git clone "https://github.com/zsh-users/zsh-history-substring-search" "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search"'
    zsh -c 'git clone "https://github.com/zsh-users/zsh-syntax-highlighting.git" "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"'
}

function InstallWindows {
    
}

switch ($true) {
    $IsLinux { InstallLinux }
    $IsMacOS { InstallMacOS }
    $IsWindows { InstallWindows }
    Default { Write-Error -Message "Could not determine host operating system." }
}

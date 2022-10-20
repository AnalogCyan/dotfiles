#!/usr/bin/env pwsh

function InstallLinux {
    if (-Not $(Get-Command "apt")) {
        Write-Error "This script was only designed for debian-based systems. Aborting."
        exit
    }

    sudo bash -c "apt update --fix-missing && apt upgrade && apt autoremove && apt --fix-broken install"
    sudo apt install gcc g++ git vim htop zsh fish fortune mosh screen

}

function InstallMacOS {
    New-Item -Path "$HOME/bin/apps/pfetch/" -ItemType Directory -Force
    Copy-Item -Path "./macOS/Users/cyan/bin/" -Destination "$HOME/bin/" -Force -Recurse
    git clone "https://github.com/dylanaraps/pfetch.git" "$HOME/bin/apps/pfetch/"

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    New-Item -Path "$HOME/.oh-my-zsh/custom/" -ItemType Directory -Force
    Move-Item -Path "$HOME/.zshrc" -Destination "$HOME/.zshrc.dotbak" -Force
    Copy-Item -Path "./macOS/Users/cyan/.zshrc" "$HOME/.zshrc" -Force
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
    function add_to_path {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $path,
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [bool]
            $system
        )
    }
    function install_winget_app {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $ID
        )
        $n = winget upgrade --silent --accept-package-agreements --accept-source-agreements --force -e $name
        if ($n -eq "No installed package found matching input criteria.") {
            winget install --silent --accept-package-agreements --accept-source-agreements --force -e $name
        }
    }
    function Get-Updates {
        $command = 'Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName UpdateScanMethod; if (-not(Get-Command PSWindowsUpdate -ErrorAction SilentlyContinue)) { Install-Module -ErrorAction SilentlyContinue -Name PSWindowsUpdate -Force }; Import-Module PSWindowsUpdate; Install-WindowsUpdate -AcceptAll -IgnoreReboot -MicrosoftUpdate -NotCategory "Drivers" -RecurseCycle 2'
        Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile $command" -Wait
    }
}

switch ($true) {
    $IsLinux { if ((id -u) -eq 0) { throw "This script should not be run as administrator!" } else { InstallLinux } }
    $IsMacOS { if ((id -u) -eq 0) { throw "This script should not be run as administrator!" } else { InstallMacOS } }
    $IsWindows { if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { throw "This script should not be run as administrator!" } else { InstallWindows } }
    Default { throw "Could not determine host operating system." }
}

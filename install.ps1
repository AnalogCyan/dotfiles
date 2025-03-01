#!pwsh
# =============================================================================
#
#  Dotfiles Installer Script for Windows Systems
#
#  Author: AnalogCyan
#  License: Unlicense
#
# =============================================================================

# =============================================================================
# CONFIGURATION
# =============================================================================

# Package lists - easy to update in the future
$CHOCO_APPS = @(
  "autohotkey"
  "chocolateygui"
  "cascadia-code-nerd-font"
  "firacode"
  "firacodenf"
  "mingw"
  "ffmpeg"
  "gawk"
  "patch"
  "sed"
  "bat"
  "ventoy"
  "waifu2x-caffe"
  "yt-dlp"
  "autoclicker"
  "itch"
)

$WINGET_APPS = @(
  "1password-cli"
  "AgileBits.1Password"
  "AltSnap.AltSnap"
  "Audacity.Audacity"
  "CodeSector.TeraCopy"
  "CPUID.CPU-Z"
  "CPUID.HWMonitor"
  "DelugeTeam.DelugeBeta"
  "EclipseAdoptium.Temurin.17"
  "ElectronicArts.EADesktop"
  "GIMP.GIMP"
  "Git.Git"
  "GitHub.cli"
  "GitHub.GitLFS"
  "GnuPG.Gpg4win"
  "Google.AndroidStudio"
  "HandBrake.HandBrake"
  "Initex.YogaDNS"
  "Insecure.Nmap"
  "Jaquadro.NBTExplorer"
  "KDE.Kdenlive"
  "KDE.KDiff3"
  "Kitware.CMake"
  "LLVM.LLVM"
  "Logitech.Options"
  "Logitech.UnifyingSoftware"
  "Malwarebytes.Malwarebytes"
  "Microsoft.GitCredentialManagerCore"
  "Microsoft.WindowsSDK"
  "Obsidian.Obsidian"
  "Ombrelin.PlexRichPresence"
  "OpenJS.NodeJS"
  "Plex.Plex"
  "Plex.Plexamp"
  "Plex.PlexMediaServer"
  "Python.Python.3"
  "QMK.QMKToolbox"
  "RaspberryPiFoundation.RaspberryPiImager"
  "REALiX.HWiNFO"
  "Spotify.Spotify" # Specifically the non-store version for spicetify compatibility
  "Telegram.TelegramDesktop"
  "TimKosse.FileZilla.Client"
  "Twitch.TwitchStudio"
  "Ubisoft.Connect"
  "Unchecky.Uncheck"
  "Valve.Steam"
  "vim.vim"
  "Win32diskimager.win32diskimager"
  "WindscribeLimited.Windscribe"
  "WiresharkFoundation.Wireshark"
  "Yarn.Yarn"
  "9MT60QV066RP" # ModernFlyouts
  "9MV0B5HZVK9Z" # Xbox
  "9MWV79XLFQH7" # Fluent Screen Recorder
  "9MZ1SNWT0N5D" # PowerShell
  "9N0DX20HK701" # Windows Terminal
  "9N1SV6841F0B" # Tubi TV
  "9N1Z0JXB224X" # UUP Media Creator
  "9N26S50LN705" # Windows File Recovery
  "9N4P75DXL6FG" # WSATools
  "9N8G7TSCL18R" # NanaZip
  "9NBLGGGZ5QDQ" # Xbox Avatars
  "9NBLGGH30XJ3" # Xbox Accessories
  "9NBLGGH4V0R3" # Xbox Avatar Editor
  "9NBLGGH5R558" # Microsoft To Do
  "9NGHP3DX8HDX" # Files App
  "9NH1HGNGHB0W" # App Packages Viewer
  "9NJHK44TTKSX" # Amazon Appstore
  "9NLVH2LL4P1Z" # Videotape
  "9NV4BS3L1H4S" # QuickLook
  "9NZKPSTSNW4P" # Xbox Game Bar
  "9P6PMZTM93LR" # Microsoft Defender Preview
  "9P7KNL5RWT25" # Sysinternals
  "9P9TQF7MRM4R" # Windows Subsystem for Linux Preview
  "9PC3H3V7Q9CH" # Rufus
  "9PD9BHGLFC7H" # Inkscape
  "9PDXGNCFSCZV" # Ubuntu WSL
  "9PGCV4V3BK4W" # DevToys
  "9PGW18NPBZV5" # Minecraft Launcher
  "9PLDPG46G47Z" # Xbox Insider Hub
  "9PNNWB4TQ5H0" # Free Duplicate Finder
  "9WZDNCRF0083" # Messenger
  "9WZDNCRFHWLH" # HP Smart
  "9WZDNCRFHWQT" # Drawboard PDF
  "9WZDNCRFJ3L1" # Hulu
  "9WZDNCRFJ3PS" # Microsoft Remote Desktop
  "9WZDNCRFJ3PV" # Windows Scan
  "9WZDNCRFJ3TJ" # Netflix
  "9WZDNCRFJBD8" # Xbox Console Companion
  "XP89DCGQ3K6VLD" # Microsoft PowerToys
  "XP8BX7ZFN357DS" # Playnite
  "XP99VR1BPSBQJ2" # Epic Games
  "XP9KHM4BK9FZ7Q" # Visual Studio Code
  "XPDC2RH70K22MN" # Discord
  "XPDCFJDKLZJLP8" # Visual Studio Community 2022
)

# Git configuration
$GIT_USER_NAME = "AnalogCyan"
$GIT_USER_EMAIL = "git@thayn.me"

# Paths
$DOTFILES_DIR = Get-Location
$POWERSHELL_PROFILE_DIR = Split-Path -Parent $PROFILE

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Colors for terminal output
$COLOR_RED = 'DarkRed'
$COLOR_GREEN = 'DarkGreen'
$COLOR_YELLOW = 'DarkYellow'
$COLOR_BLUE = 'DarkBlue'

function Write-LogInfo {
  param([string]$Message)
  Write-Host "INFO: " -ForegroundColor $COLOR_BLUE -NoNewline
  Write-Host $Message
}

function Write-LogSuccess {
  param([string]$Message)
  Write-Host "SUCCESS: " -ForegroundColor $COLOR_GREEN -NoNewline
  Write-Host $Message
}

function Write-LogWarning {
  param([string]$Message)
  Write-Host "WARNING: " -ForegroundColor $COLOR_YELLOW -NoNewline
  Write-Host $Message
}

function Write-LogError {
  param([string]$Message)
  Write-Host "ERROR: " -ForegroundColor $COLOR_RED -NoNewline
  Write-Host $Message
}

function Confirm-Action {
  param([string]$Message)
  $response = Read-Host -Prompt "$Message (y/n)"
  return $response -match '^[yY]$'
}

function Install-WingetApp {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $name
  )
  
  Write-LogInfo "Installing $name via Windows Package Manager..."
  $n = winget upgrade --accept-package-agreements --accept-source-agreements --force -e $name
  if ($n -match "No installed package found matching input criteria.") {
    winget install --accept-package-agreements --accept-source-agreements --force -e $name
  }
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

function Test-SystemRequirements {
  Write-LogInfo "Checking system requirements..."

  # Check if the script is running on Windows 10 or 11
  if ([System.Environment]::OSVersion.Version.Major -lt 10) {
    Write-LogError "This script is only compatible with Windows 10 or 11!"
    exit 1
  }

  # Check if the script is running with administrative privileges
  $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
  if ($isAdmin) {
    Write-LogError "Script cannot be run as administrator!"
    exit 1
  }

  Write-LogSuccess "System requirements check passed."
}

function Set-SystemConfiguration {
  Write-LogInfo "Configuring system settings..."

  # Virtualization enable check and WSL update
  if ((Get-Command wsl.exe -ErrorAction SilentlyContinue) -and (Get-Command ubuntu.exe -ErrorAction SilentlyContinue)) {
    Write-LogInfo "Configuring WSL..."
    wsl --set-default-version 2
    wsl -- ./install.sh
  }
  elseif (-not (Get-Command hvc.exe -ErrorAction SilentlyContinue) -or (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    Write-LogInfo "Enabling virtualization features (Hyper-V, Sandbox, WSL, etc.)..."
    Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile wsl --enable; Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart | Out-Null; Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart | Out-Null; Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -All -NoRestart | Out-Null" -Wait
  }

  Write-LogSuccess "System configuration completed."
}

function Update-System {
  Write-LogInfo "Ensuring system is up-to-date..."

  $command = 'Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName UpdateScanMethod; if (-not(Get-Command PSWindowsUpdate -ErrorAction SilentlyContinue)) { Install-Module -ErrorAction SilentlyContinue -Name PSWindowsUpdate -Force }; Import-Module PSWindowsUpdate; Install-WindowsUpdate -AcceptAll -IgnoreReboot -MicrosoftUpdate -NotCategory "Drivers" -RecurseCycle 2'
  Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile $command" -Wait

  Write-LogSuccess "System update check completed."
}

function Install-PackageManagers {
  Write-LogInfo "Installing package managers..."

  # Install Chocolatey
  if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Write-LogInfo "Installing Chocolatey..."
    Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" -Wait
    refreshenv
  }
  else {
    Write-LogInfo "Chocolatey is already installed."
  }

  # Install Windows Package Manager
  if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    Write-LogInfo "Installing Windows Package Manager..."
    Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile choco install winget -y" -Wait
    refreshenv
  }
  else {
    Write-LogInfo "Windows Package Manager is already installed."
  }

  Write-LogSuccess "Package managers installation completed."
}

function Install-Applications {
  Write-LogInfo "Installing applications..."

  # Install Chocolatey applications
  Write-LogInfo "Installing Chocolatey applications..."
  $chocoAppsString = $CHOCO_APPS -join " "
  Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile choco upgrade -y $chocoAppsString" -Wait

  # Install Winget applications
  Write-LogInfo "Installing Windows Package Manager applications..."
  foreach ($app in $WINGET_APPS) {
    Install-WingetApp -name $app
  }

  # Install Terminal-Icons
  Write-LogInfo "Installing Terminal-Icons PowerShell module..."
  if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force
  }
  else {
    Write-LogInfo "Terminal-Icons module is already installed."
  }

  # Install Starship prompt
  Write-LogInfo "Installing Starship prompt..."
  Install-WingetApp -name "Starship.Starship"

  # Install Flutter
  Write-LogInfo "Installing Flutter SDK..."
  $flutterPath = "C:\Users\cyan\AppData\Local\Android\flutter"
  if (-not (Test-Path $flutterPath)) {
    New-Item -Force -ItemType Directory -Path "C:\Users\cyan\AppData\Local\Android"
    git clone https://github.com/flutter/flutter.git -b stable $flutterPath
  }
  else {
    Write-LogInfo "Flutter is already installed. Updating..."
    Push-Location $flutterPath
    git pull
    Pop-Location
  }

  Write-LogSuccess "Applications installation completed."
}

function Install-PowerShellModules {
  Write-LogInfo "Installing PowerShell modules..."

  # Install Oh-My-Posh
  if (-not (Get-Command oh-my-posh.exe -ErrorAction SilentlyContinue)) {
    Write-LogInfo "Installing Oh-My-Posh..."
    winget install JanDeDobbeleer.OhMyPosh -s winget
  }
  else {
    Write-LogInfo "Updating Oh-My-Posh..."
    winget upgrade JanDeDobbeleer.OhMyPosh -s winget
  }

  # Install PSReadLine
  if (-not (Get-Module -ListAvailable -Name PSReadLine)) {
    Write-LogInfo "Installing PSReadLine..."
    Install-Module -Name PSReadLine -Force
  }
  else {
    Write-LogInfo "PSReadLine is already installed."
  }

  Write-LogSuccess "PowerShell modules installation completed."
}

function Install-StarshipPrompt {
  Write-LogInfo "Configuring Starship prompt..."
  
  # Create .config directory if it doesn't exist
  $configDir = "$env:USERPROFILE\.config"
  if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-LogInfo "Created config directory at $configDir"
  }
  
  # Copy starship.toml from dotfiles repo
  $starshipConfigSource = Join-Path $DOTFILES_DIR "starship.toml"
  $starshipConfigDest = Join-Path $configDir "starship.toml"
  
  if (Test-Path $starshipConfigSource) {
    Copy-Item -Path $starshipConfigSource -Destination $starshipConfigDest -Force
    Write-LogInfo "Copied starship.toml to $starshipConfigDest"
  }
  else {
    Write-LogError "starship.toml not found at $starshipConfigSource"
    Write-LogInfo "Creating fallback configuration..."
    curl.exe -sS https://starship.rs/presets/toml/minimal.toml -o $starshipConfigDest
  }

  # Update PowerShell profile to initialize Starship
  if (-not (Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force | Out-Null
    Write-LogInfo "Created new PowerShell profile at $PROFILE"
  }
  
  # Check if Starship initialization is already in the profile
  $profileContent = Get-Content -Path $PROFILE -ErrorAction SilentlyContinue
  if (-not ($profileContent -match "Invoke-Expression .*starship init powershell.*")) {
    Add-Content -Path $PROFILE -Value "`n# Initialize Starship prompt`nInvoke-Expression (&starship init powershell)" -Force
    Write-LogInfo "Added Starship initialization to PowerShell profile"
  }
  else {
    Write-LogInfo "Starship initialization already in PowerShell profile"
  }
  
  Write-LogSuccess "Starship prompt configured."
}

function Install-DotfilesConfigs {
  Write-LogInfo "Installing dotfiles configurations..."

  # Create PowerShell profile directory if it doesn't exist
  if (-not (Test-Path $POWERSHELL_PROFILE_DIR)) {
    New-Item -ItemType Directory -Path $POWERSHELL_PROFILE_DIR -Force | Out-Null
  }

  # Copy PowerShell profile from Windows directory
  $sourcePSProfile = Join-Path $DOTFILES_DIR "Windows\Profile.ps1"
  if (Test-Path $sourcePSProfile) {
    Write-LogInfo "Installing PowerShell profile..."
    Copy-Item -Path $sourcePSProfile -Destination $PROFILE -Force
    
    # Ensure Starship initialization is in the profile
    $profileContent = Get-Content -Path $PROFILE -ErrorAction SilentlyContinue
    if (-not ($profileContent -match "Invoke-Expression .*starship init powershell.*")) {
      Add-Content -Path $PROFILE -Value "`n# Initialize Starship prompt`nInvoke-Expression (&starship init powershell)" -Force
      Write-LogInfo "Added Starship initialization to PowerShell profile"
    }
  }
  else {
    Write-LogWarning "PowerShell profile not found at $sourcePSProfile"
  }

  # Copy Windows Terminal settings
  $terminalSettingsSource = Join-Path $DOTFILES_DIR "Windows\Terminal\settings.json"
  $terminalSettingsDestination = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
  if (Test-Path $terminalSettingsSource) {
    Write-LogInfo "Installing Windows Terminal settings..."
    Copy-Item -Path $terminalSettingsSource -Destination $terminalSettingsDestination -Force
  }
  else {
    Write-LogWarning "Windows Terminal settings not found at $terminalSettingsSource"
  }

  # Copy Winget settings
  $wingetSettingsSource = Join-Path $DOTFILES_DIR "Windows\winget\settings.json"
  $wingetSettingsDestination = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"
  if (Test-Path $wingetSettingsSource) {
    Write-LogInfo "Installing Winget settings..."
    Copy-Item -Path $wingetSettingsSource -Destination $wingetSettingsDestination -Force
  }
  else {
    Write-LogWarning "Winget settings not found at $wingetSettingsSource"
  }

  Write-LogSuccess "Dotfiles configurations installed."
}

function Set-GitConfiguration {
  Write-LogInfo "Configuring Git..."

  if (Get-Command git -ErrorAction SilentlyContinue) {
    # Choose appropriate editor based on environment
    $editor = if (Get-Command code -ErrorAction SilentlyContinue) {
      "code --wait -n"
    }
    else {
      "vim"
    }

    # Set Git configuration
    git config --global core.editor $editor
    git config --global user.name $GIT_USER_NAME
    git config --global user.email $GIT_USER_EMAIL

    Write-LogSuccess "Git configuration completed."
  }
  else {
    Write-LogWarning "Git is not installed. Cannot configure Git."
  }
}

function Install-SSHConfig {
  Write-LogInfo "Setting up SSH configuration..."

  $sshPath = "$env:USERPROFILE\.ssh"
  
  # Create .ssh directory if it doesn't exist
  if (-not (Test-Path $sshPath)) {
    New-Item -ItemType Directory -Path $sshPath -Force | Out-Null
    Write-LogInfo "Created SSH directory at $sshPath"
  }

  # TODO: Implement SSH key copy or generation logic here

  Write-LogSuccess "SSH configuration completed."
}

# =============================================================================
# MAIN SCRIPT
# =============================================================================

function Start-Installation {
  # Print banner
  Write-Host "=====================================" -ForegroundColor Cyan
  Write-Host "  Windows Dotfiles Installation Script" -ForegroundColor Cyan
  Write-Host "=====================================" -ForegroundColor Cyan
  Write-Host ""

  # Check if user is aware this script assumes the user is running a fresh up-to-date Windows installation
  Write-Host "This script assumes the user is running a fresh up-to-date Windows installation."
  Write-Host "Please ensure you have backed up all important data before running this script."
  Read-Host -Prompt "Press Enter to continue or Ctrl+C to cancel"

  # Run installation steps
  Test-SystemRequirements
  Set-SystemConfiguration
  Update-System
  Install-PackageManagers
  Install-Applications
  Install-PowerShellModules
  Install-StarshipPrompt
  Install-DotfilesConfigs
  Set-GitConfiguration
  Install-SSHConfig

  # TODO: Additional tasks as noted in the original script
  # - Configure paths
  # - Install Win11 cursors
  # - Configure additional settings

  # Completion message
  Write-Host ""
  Write-Host "=====================================" -ForegroundColor Cyan
  Write-LogSuccess "Dotfiles installation complete!"
  Write-Host "=====================================" -ForegroundColor Cyan
  
  if (Confirm-Action "Would you like to restart your computer now to complete the setup?") {
    Write-LogInfo "Restarting system..."
    Restart-Computer
  }
  else {
    Write-LogInfo "No restart selected. Some changes may require a restart to take effect."
  }
}

# Execute the installation
Start-Installation

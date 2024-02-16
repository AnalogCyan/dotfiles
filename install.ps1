#!pwsh
# A simple script for installing my dotfiles on Windows.

# Define functions for differnet installation steps

function install_winget_app {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $name
  )
  $n = winget upgrade --interactive --accept-package-agreements --accept-source-agreements --force -e $name
  if ($n -match "No installed package found matching input criteria.") {
    winget install --interactive --accept-package-agreements --accept-source-agreements --force -e $name
  }
}

function Set-SystemConfiguration {
  # Virtualization enable check and WSL update
  if ((Get-Command wsl.exe -ErrorAction SilentlyContinue) -and (Get-Command ubuntu.exe -ErrorAction SilentlyContinue)) {
    wsl --set-default-version 2
    wsl -- ./install.sh
  }
  elseif ( -not (Get-Command hvc.exe -ErrorAction SilentlyContinue) -or (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    Write-Output "Enabling virtualization features (Hyper-V, Sandbox, WSL, etc.)..."
    Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile wsl --enable; Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart | Out-Null; Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart | Out-Null; Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -All -NoRestart | Out-Null" -Wait
  }
}

function Get-Updates {
  Write-Output
  Write-Output "⏫ Ensuring system is up-to-date..."

  $command = 'Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName UpdateScanMethod; if (-not(Get-Command PSWindowsUpdate -ErrorAction SilentlyContinue)) { Install-Module -ErrorAction SilentlyContinue -Name PSWindowsUpdate -Force }; Import-Module PSWindowsUpdate; Install-WindowsUpdate -AcceptAll -IgnoreReboot -MicrosoftUpdate -NotCategory "Drivers" -RecurseCycle 2'
  Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile $command" -Wait
}

function Install-PackageManagers {
  Write-Output
  Write-Output "📦 Installing package managers..."

  # Install Chocolatey
  if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" -Wait
    refreshenv
  }

  # Install Windows Package Manager
  if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile choco install winget -y" -Wait
    refreshenv
  }
}

function Install-Apps {
  Write-Output
  Write-Output "📦 Installing packages..."

  # Define the apps to be installed
  [string[]] $choco_apps = @(
    "autohotkey",
    "chocolateygui",
    "cascadia-code-nerd-font",
    "firacode",
    "firacodenf",
    "mingw",
    "ffmpeg",
    "gawk",
    "patch",
    "sed",
    "bat",
    "ventoy",
    "waifu2x-caffe",
    "yt-dlp",
    "autoclicker",
    "itch"
  )
  [string[]] $winget_apps = @(
    "1password-cli"
    "AgileBits.1Password",
    "AltSnap.AltSnap",
    "Audacity.Audacity",
    "CodeSector.TeraCopy",
    "CPUID.CPU-Z",
    "CPUID.HWMonitor",
    "DelugeTeam.DelugeBeta",
    "EclipseAdoptium.Temurin.17",
    "ElectronicArts.EADesktop",
    "GIMP.GIMP",
    "Git.Git",
    "GitHub.cli",
    "GitHub.GitLFS",
    "GnuPG.Gpg4win",
    "Google.AndroidStudio",
    "HandBrake.HandBrake",
    "Initex.YogaDNS",
    "Insecure.Nmap",
    "Jaquadro.NBTExplorer",
    "KDE.Kdenlive",
    "KDE.KDiff3",
    "Kitware.CMake",
    "LLVM.LLVM",
    "Logitech.Options",
    "Logitech.UnifyingSoftware",
    "Malwarebytes.Malwarebytes",
    "Microsoft.GitCredentialManagerCore",
    "Microsoft.WindowsSDK",
    "Obsidian.Obsidian",
    "Ombrelin.PlexRichPresence",
    "OpenJS.NodeJS",
    "Plex.Plex",
    "Plex.Plexamp",
    "Plex.PlexMediaServer",
    "Python.Python.3",
    "QMK.QMKToolbox",
    "RaspberryPiFoundation.RaspberryPiImager",
    "REALiX.HWiNFO",
    "Spotify.Spotify", # Specifically the non-store version for spicetify compatibility
    "Telegram.TelegramDesktop",
    "TimKosse.FileZilla.Client",
    "Twitch.TwitchStudio",
    "Ubisoft.Connect",
    "Unchecky.Uncheck",
    "Valve.Steam",
    "vim.vim",
    "Win32diskimager.win32diskimager",
    "WindscribeLimited.Windscribe",
    "WiresharkFoundation.Wireshark",
    "Yarn.Yarn",
    "9MT60QV066RP", # ModernFlyouts
    "9MV0B5HZVK9Z", # Xbox
    "9MWV79XLFQH7", # Fluent Screen Recorder
    "9MZ1SNWT0N5D", # PowerShell
    "9N0DX20HK701", # Windows Terminal
    "9N1SV6841F0B", # Tubi TV
    "9N1Z0JXB224X", # UUP Media Creator
    "9N26S50LN705", # Windows File Recovery
    "9N4P75DXL6FG", # WSATools
    "9N8G7TSCL18R", # NanaZip
    "9NBLGGGZ5QDQ", # Xbox Avatars
    "9NBLGGH30XJ3", # Xbox Accessories
    "9NBLGGH4V0R3", # Xbox Avatar Editor
    "9NBLGGH5R558", # Microsoft To Do
    "9NGHP3DX8HDX", # Files App
    "9NH1HGNGHB0W", # App Packages Viewer
    "9NJHK44TTKSX", # Amazon Appstore
    "9NLVH2LL4P1Z", # Videotape
    "9NV4BS3L1H4S", # QuickLook
    "9NZKPSTSNW4P", # Xbox Game Bar
    "9P6PMZTM93LR", # Microsoft Defender Preview
    "9P7KNL5RWT25", # Sysinternals
    "9P9TQF7MRM4R", # Windows Subsystem for Linux Preview
    "9PC3H3V7Q9CH", # Rufus
    "9PD9BHGLFC7H", # Inkscape
    "9PDXGNCFSCZV", # Ubuntu WSL
    "9PGCV4V3BK4W", # DevToys
    "9PGW18NPBZV5", # Minecraft Launcher
    "9PLDPG46G47Z", # Xbox Insider Hub
    "9PNNWB4TQ5H0", # Free Duplicate Finder
    "9WZDNCRF0083", # Messenger
    "9WZDNCRFHWLH", # HP Smart
    "9WZDNCRFHWQT", # Drawboard PDF
    "9WZDNCRFJ3L1", # Hulu
    "9WZDNCRFJ3PS", # Microsoft Remote Desktop
    "9WZDNCRFJ3PV", # Windows Scan
    "9WZDNCRFJ3TJ", # Netflix
    "9WZDNCRFJBD8", # Xbox Console Companion
    "XP89DCGQ3K6VLD", # Microsoft PowerToys
    "XP8BX7ZFN357DS", # Playnite
    "XP99VR1BPSBQJ2", # Epic Games
    "XP9KHM4BK9FZ7Q", # Visual Studio Code
    "XPDC2RH70K22MN", # Discord
    "XPDCFJDKLZJLP8" # Visual Studio Community 2022
  )

  # Install choco_apps
  Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile choco upgrade -y $choco_apps" -Wait

  # Install winget_apps
  foreach ($app in $winget_apps) {
    Write-Host "* Installing $app via Windows Package Manager" -ForegroundColor Green
    install_winget_app($app)
  }

  # Install Terminal-Icons
  Install-Module -Name Terminal-Icons -Repository PSGallery

  # Install Flutter to Android directory
  New-Item -Force -ItemType Directory -Path "C:\Users\cyan\AppData\Local\Android"
  powershell.exe -NoProfile -Command 'git clone https://github.com/flutter/flutter.git -b stable C:\Users\cyan\AppData\Local\Android\flutter'
}

## MAIN SCRIPT ##

# Check if the script is running as administrator
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Write-Output "ERROR: Script cannot be run as administrator!"
  exit 1
}

# Check if the script is running on Windows 10 or 11
if ($PSVersionTable.PSVersion.Major -lt 10) {
  Write-Output "ERROR: This script is only compatible with Windows 10 or 11!"
  exit 1
}

# Check if user is aware this script assumes the user is running a fresh up-to-date Windows installation
Write-Output "This script assumes the user is running a fresh up-to-date Windows installation."
Write-Output "Please ensure you have backed up all important data before running this script."
Read-Host -Prompt 'Press any key to continue script.'

Set-SystemConfiguration
Get-Updates
Install-PackageManagers
Install-Apps

#! TODO:
#? C:\Users\cyan\.ssh
#? .gitconfig
#? add stuff to user/system path as needed
#? Win11 cursors
#? oh-my-posh

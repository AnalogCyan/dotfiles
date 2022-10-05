if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Write-Output "ERROR: This script cannot be run as administrator!"
  exit 1
}

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
    $name
  )
  $n = winget upgrade --interactive --accept-package-agreements --accept-source-agreements --force -e $name
  if ($n -eq "No installed package found matching input criteria.") {
    winget install --interactive --accept-package-agreements --accept-source-agreements --force -e $name
  }
}

[string[]] $choco_apps = @(
  "autohotkey",
  "chocolateygui",
  "gsudo", # moved back to choco due to bug w/ the winget version of installer
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

function Get-Updates {
  $command = 'Get-CimInstance -Namespace "Root\cimv2\mdm\dmmap" -ClassName "MDM_EnterpriseModernAppManagement_AppManagement01" | Invoke-CimMethod -MethodName UpdateScanMethod; if (-not(Get-Command PSWindowsUpdate -ErrorAction SilentlyContinue)) { Install-Module -ErrorAction SilentlyContinue -Name PSWindowsUpdate -Force }; Import-Module PSWindowsUpdate; Install-WindowsUpdate -AcceptAll -IgnoreReboot -MicrosoftUpdate -NotCategory "Drivers" -RecurseCycle 2'
  Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile $command" -Wait
}

Write-Output "Ensuring the system is up-to-date..."
Write-Output "Please manually check Windows Update & Microsoft Store to ensure all updates have applied correctly, and if updates require a reboot."
Get-Updates
Read-Host -Prompt 'Once you are sure the system is up-to-date, press any key to continue script.'

if ((Get-Command wsl.exe -ErrorAction SilentlyContinue) -and (Get-Command ubuntu.exe -ErrorAction SilentlyContinue)) {
  wsl --set-default-version 2
  wsl -- sudo apt-get update -y
  wsl -- sudo apt-get upgrade -y
  #wsl -- ./install.sh
}
elseif ( -not (Get-Command hvc.exe -ErrorAction SilentlyContinue) -or (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
  Write-Output "Enabling virtualization features (Hyper-V, Sandbox, WSL, etc.)..."
  Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile wsl --enable; Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart | Out-Null; Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart | Out-Null; Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -All -NoRestart | Out-Null" -Wait
}

#TODO: add prompt here
if (Get-Command chocolatey.exe -ErrorAction SilentlyContinue) {
  Write-Output "Existing Chocolatey install detected, attempting updates..."
  Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile choco upgrade all -y" -Wait
  refreshenv
}
else {
  Write-Output "Installing Chocolatey..."
  Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" -Wait
  refreshenv
}

if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
  Write-Output "Existing winget install detected, attempting updates..."
  winget upgrade --all
  refreshenv
}
else {
  Write-Output "Winget could not be found, please ensure all apps are up-to-date."
  Start-Process ms-windows-store:updates
  exit
}

Write-Host "* Installing [$choco_apps] via Chocolatey" -ForegroundColor Green
Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile choco upgrade -y $choco_apps" -Wait
winget uninstall Cortana
foreach ($app in $winget_apps) {
  Write-Host "* Installing $app via Windows Package Manager" -ForegroundColor Green
  install_winget_app($app)
}
Install-Module -Name Terminal-Icons -Repository PSGallery
# Install Flutter to Android directory
New-Item -Force -ItemType Directory -Path "C:\Users\cyan\AppData\Local\Android"
powershell.exe -NoProfile -Command 'git clone https://github.com/flutter/flutter.git -b stable C:\Users\cyan\AppData\Local\Android\flutter'
# Install 1Password CLI 2.0
# https://developer.1password.com/docs/cli/get-started/
# ???

# C:\Users\cyan\.ssh

# .gitconfig

# don't include ahk script, it is now redundant (unless I switch keyboards again...)

# add stuff to user/system path as needed

# Win11 cursors

# spicetify-cli

param(
  [switch]$w = $false,
  $flags
)

# Grab directory of script
$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

function pwshProfile {
  $CurrentUserAllHosts_Path = pwsh.exe -NoProfile -Command Split-Path "`$PROFILE.CurrentUserAllHosts"
  Write-Output "Copying pwsh profile & functions into $CurrentUserAllHosts_Path\..."
  Copy-Item -Force ".\profile.ps1" -Destination (New-Item -Path "$CurrentUserAllHosts_Path\" -ItemType "file" -name "Profile.ps1" -Force)
  Copy-Item -Force .\functions -Destination $CurrentUserAllHosts_Path\ -Recurse
}

function wslRestart {
  Write-Output "powershell.exe -NoProfile $curDir\install.ps1 -w" > "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\startup.cmd"
  Write-Warning "A reboot is required to finish setup. Press enter to reboot.`nScript will resume after reboot."
  Restart-Computer -Confirm
}

# ! Running wsl-distro installer as admin makes it only accessable to admin consoles
# ! Run check to ensure running in powershell and not pwsh, as running updates
# ! in pwsh when pwsh has an update can break it
if ($d) {
  if (Get-Command chocolatey.exe -errorAction SilentlyContinue) {
    Write-Output "Existing Chocolatey install detected, attempting updates..."
    choco upgrade all -y
  }
  else {
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  }
  Write-Output "Installing tools and dependencies..."
  choco install microsoft-edge powertoys microsoft-windows-terminal powershell-core firacode-ttf mingw git vscode androidstudio vim hwmonitor -y
  if ($p) {
    Write-Warning "A new version of PowerShell was installed, profiles & functions must now be updated."
    pwshProfile
  }
  $sw = Read-Host -Prompt 'Install additional software? (y/N)'
  if ($sw -eq "y" -or $sw -eq "Y") {
    choco install googlechrome firefox 7zip vlc autohotkey malwarebytes gimp python filezilla inkscape virtualbox rufus youtube-dl audacity steam deluge kdenlive spotify windscribe teracopy obs-studio edgedeflector discord autoit unchecky krita screentogif picpick.portable dopamine sdformatter 1password -y
  }
  if ([System.Environment]::OSVersion.Version.Build -ge 18917) {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart | Out-Null
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
    wslRestart
  }
  elseif ([System.Environment]::OSVersion.Version.Build -lt 18917) {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart | Out-Null
    wslRestart
  }
  else {
    Write-Error -Message "Unrecognized system build number."
    Break
  }
}

if ($w) {
  wsl --set-default-version 2
  Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu -OutFile Ubuntu.appx -UseBasicParsing
  Add-AppxPackage .\Ubuntu.appx
  Write-Warning ""
  Start-Process wsl.exe
  Read-Host -Prompt 'Opening wsl for the first time. Once you complete setup, come back here and press enter to continue.'
  wsl -- sudo apt update
  wsl -- sudo apt upgrade
  wsl -- ../Linux/install.sh
  Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\startup.cmd" -Force
  Break
}

$pfunc = Read-Host -Prompt 'Install pwsh profile/functions? (y/N)'
$ahk = Read-Host -Prompt 'Install ahk scripts? (y/N)'
$wterm = Read-Host -Prompt 'Install Terminal config? (y/N)'
$gitconf = Read-Host -Prompt 'Install git config? (y/N)'
$mcsym = Read-Host -Prompt 'Create .minecraft -> OneDrive symbolic link? (y/N)'

Set-Location $curDir

if ($pfunc -eq "y" -or $pfunc -eq "Y") {
  $CurrentUserAllHosts_Path = powershell.exe -NoProfile -Command Split-Path "`$PROFILE.CurrentUserAllHosts"
  Write-Output "Copying pwsh profile & functions into $CurrentUserAllHosts_Path\..."
  Copy-Item -Force ".\profile.ps1" -Destination (New-Item -Path "$CurrentUserAllHosts_Path\" -ItemType "file" -name "Profile.ps1" -Force)
  Copy-Item -Force .\functions -Destination $CurrentUserAllHosts_Path\ -Recurse
  $flags += "p"
  if (Get-Command pwsh.exe -errorAction SilentlyContinue) {
    pwshProfile
  }
}

if ($ahk -eq "y" -or $ahk -eq "Y") {
  Write-Output "Copying ahk scripts into $env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\..."
  Copy-Item -Force '.\ahk\win_tweaks.exe' -Destination "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
}


if ($wterm -eq "y" -or $wterm -eq "Y") {
  Write-Output "Copying Terminal config into $env:HOMEPATH\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\..."
  Copy-Item -Force '.\profiles.json' -Destination "$env:HOMEPATH\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
}

if ($gitconf -eq "y" -or $gitconf -eq "Y") {
  Write-Output "Copying git config into $env:HOMEPATH\..."
  Copy-Item -Force '.\.gitconfig' -Destination "$env:HOMEPATH"
}

if ($mcsym -eq "y" -or $mcsym -eq "Y") {
  Write-Output "Creating link from $env:APPDATA\.minecraft\ to $env:HOMEPATH\OneDrive\Games\Minecraft\Install\..."
  cmd /c "mklink /J %appdata%\.minecraft %homepath%\OneDrive\Games\Minecraft\Install"
}

$dep = Read-Host -Prompt 'Dotfiles installed. Attempt to install dependencies? This will prompt for admin. (y/N)'
if ($dep -eq "y" -or $dep -eq "Y") {
  $flags += "d"
  If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process -WindowStyle hidden powershell.exe -Verb runAs -ArgumentList "$curDir\setup.ps1 $flags"
  }
}
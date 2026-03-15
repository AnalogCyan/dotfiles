#!pwsh
# =============================================================================
#
#  Dotfiles Installer Script for Windows
#
#  Author: AnalogCyan
#  License: Unlicense
#
# =============================================================================

param(
  [switch]$Help
)

if ($Help) {
  Write-Host "Usage: pwsh install-windows.ps1 [options]"
  Write-Host ""
  Write-Host "Options:"
  Write-Host "  -Help    Show this help message and exit"
  Write-Host ""
  Write-Host "This script installs dotfiles and configures a Windows environment."
  exit 0
}

# =============================================================================
# BOOTSTRAP
# =============================================================================

# Ensure running in PowerShell 7+ (pwsh); relaunch if not
if ($PSVersionTable.PSEdition -ne "Core") {
  if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    Write-Host "Winget required. Please install App Installer from the Microsoft Store."
    Start-Process "ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1"
    Read-Host -Prompt "Press Enter after Winget is installed"
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
  }

  if (-not (Get-Command pwsh.exe -ErrorAction SilentlyContinue)) {
    Write-Host "Installing PowerShell 7..."
    winget install --silent --accept-package-agreements --accept-source-agreements Microsoft.PowerShell
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
  }

  Write-Host "Relaunching in PowerShell 7..."
  Start-Process pwsh -ArgumentList @("-NoLogo", "-ExecutionPolicy", "Bypass", "-File", "`"$($MyInvocation.MyCommand.Path)`"") -Wait
  exit $LASTEXITCODE
}

# =============================================================================
# CONFIGURATION
# =============================================================================

$WINGET_APPS = @(
  # --- Core System & Shell ---
  "Microsoft.PowerShell"
  "Microsoft.WindowsTerminal"

  # --- Developer Essentials ---
  "Git.Git"
  "vim.vim"
  "Microsoft.VisualStudioCode.Insiders"
  "Python.Python.3.13"
  "Python.Launcher"
  "aristocratos.btop4win"
  "JesseDuffield.lazygit"
  "Microsoft.DevHome"
  "Microsoft.Sysinternals"
  "Microsoft.WinDbg"

  # --- Shell Enhancements ---
  "Starship.Starship"
  "junegunn.fzf"
  "ajeetdsouza.zoxide"
  "sharkdp.bat"
  "sharkdp.fd"
  "BurntSushi.ripgrep.MSVC"
  "eza-community.eza"
  "Helix.Helix"

  # --- Essential Utilities ---
  "Microsoft.PowerToys"
  "Seelen.SeelenUI"
  "M2Team.NanaZip"
  "Microsoft.PCManager"
  "Microsoft.OneDrive"
  "yt-dlp.yt-dlp"

  # --- Browsers ---
  "Mozilla.Firefox.Nightly.MSIX"

  # --- Productivity & Notes ---
  "Obsidian.Obsidian"

  # --- Security ---
  "AgileBits.1Password"

  # --- Communication ---
  "Discord.Discord"
)

$POWERSHELL_MODULES = @(
  "PSReadLine"
  "Terminal-Icons"
  "PSFzf"
  "posh-git"
  "PowerShellForGitHub"
  "PSWindowsUpdate"
  "BurntToast"
)

$DOTFILES_DIR = $PSScriptRoot

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

$COLOR_RED    = 'DarkRed'
$COLOR_GREEN  = 'DarkGreen'
$COLOR_YELLOW = 'DarkYellow'
$COLOR_BLUE   = 'DarkBlue'

function Write-LogInfo {
  param([string]$Message)
  Write-Host "INFO: "    -ForegroundColor $COLOR_BLUE   -NoNewline
  Write-Host $Message
}

function Write-LogSuccess {
  param([string]$Message)
  Write-Host "SUCCESS: " -ForegroundColor $COLOR_GREEN  -NoNewline
  Write-Host $Message
}

function Write-LogWarning {
  param([string]$Message)
  Write-Host "WARNING: " -ForegroundColor $COLOR_YELLOW -NoNewline
  Write-Host $Message
}

function Write-LogError {
  param([string]$Message)
  Write-Host "ERROR: "   -ForegroundColor $COLOR_RED    -NoNewline
  Write-Host $Message
}

function Confirm-Action {
  param([string]$Message)
  $response = Read-Host -Prompt "${Message} (y/n)"
  return $response -match '^[yY]$'
}

function Install-WingetApp {
  param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Name
  )
  $installed = winget list -e --id $Name 2>$null
  if ($installed -match $Name) {
    winget upgrade --silent --accept-package-agreements --accept-source-agreements -e $Name
  } else {
    winget install --silent --accept-package-agreements --accept-source-agreements -e $Name
  }
}

# =============================================================================
# SYSTEM CHECKS
# =============================================================================

function Test-SystemRequirements {
  $osVersion = [System.Environment]::OSVersion.Version
  if ($osVersion.Major -lt 10 -or ($osVersion.Major -eq 10 -and $osVersion.Build -lt 22000)) {
    Write-LogError "Windows 11 or newer required."
    exit 1
  }

  $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
  if ($isAdmin) {
    Write-LogError "Do not run this script as administrator."
    exit 1
  }

  Write-LogSuccess "System requirements check passed."
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

function Install-PackageManagers {
  if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    Write-LogInfo "Winget not found. Opening Microsoft Store..."
    try {
      Start-Process "ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1"
      $confirmation = Confirm-Action "Have you completed the Winget installation?"
      if ($confirmation) {
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
      }
    } catch {
      Write-LogError "Failed to open Microsoft Store: $($_.Exception.Message)"
    }

    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
      Write-LogError "Winget installation could not be verified."
      if (-not (Confirm-Action "Continue without Winget?")) { exit 1 }
    }
  }

  Write-LogSuccess "Package manager ready."
}

function Set-SudoSupport {
  Write-LogInfo "Configuring sudo..."

  $WinVer = [System.Environment]::OSVersion.Version
  $SupportsBuiltInSudo = ($WinVer.Major -eq 10 -and $WinVer.Build -ge 25300) -or ($WinVer.Major -ge 11 -and $WinVer.Build -ge 22631)

  if ($SupportsBuiltInSudo) {
    if (Get-Command "gsudo" -ErrorAction SilentlyContinue) {
      winget uninstall gsudo --silent
    }

    $SudoEnabled = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo" -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
    if ($SudoEnabled -ne 1) {
      Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile -Command reg add 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo' /v 'Enabled' /t REG_DWORD /d 1 /f" -Wait
    }

    $SudoMode = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo" -Name "Mode" -ErrorAction SilentlyContinue).Mode
    if ($SudoMode -ne 0) {
      Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile -Command reg add 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo' /v 'Mode' /t REG_DWORD /d 0 /f" -Wait
    }
  } else {
    if (-not (Get-Command "gsudo" -ErrorAction SilentlyContinue)) {
      winget install gerardog.gsudo --silent --accept-package-agreements --accept-source-agreements
    }
  }

  Write-LogSuccess "Sudo configured."
}

function Set-WindowsOptionalFeatures {
  Write-LogInfo "Configuring Windows Optional Features..."

  $featureScript = {
    $featuresToDisable = @(
      "WindowsMediaPlayer",
      "MicrosoftWindowsPowerShellV2",
      "MicrosoftWindowsPowerShellV2Root",
      "Recall"
    )
    foreach ($feature in $featuresToDisable) {
      $state = Get-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction SilentlyContinue
      if ($state -and $state.State -eq "Enabled") {
        Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart
      }
    }

    $featuresToEnable = @("VirtualMachinePlatform", "HypervisorPlatform")
    foreach ($feature in $featuresToEnable) {
      $state = Get-WindowsOptionalFeature -Online -FeatureName $feature
      if ($state.State -eq "Disabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart
      }
    }
  }

  $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($featureScript.ToString()))
  Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile", "-EncodedCommand", $encodedCommand -Wait

  Write-LogSuccess "Windows Optional Features configured."
}

function Install-Applications {
  Write-LogInfo "Installing applications..."
  foreach ($app in $WINGET_APPS) {
    Install-WingetApp -Name $app
  }
  Write-LogSuccess "Applications installed."
}

function Install-PowerShellModules {
  Write-LogInfo "Installing PowerShell modules..."

  if (Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue) {
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
  }
  Install-Module -Name PowerShellGet -Force -AllowClobber -SkipPublisherCheck

  foreach ($module in $POWERSHELL_MODULES) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
      Install-Module -Name $module -Scope CurrentUser -Force
    }
  }

  Write-LogSuccess "PowerShell modules installed."
}

function Install-NerdFonts {
  Write-LogInfo "Installing Monaspace Nerd Font..."

  $FontUrl      = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Monaspace.zip"
  $TempDir      = Join-Path $env:TEMP "NerdFonts_$(Get-Random)"
  $ZipPath      = Join-Path $TempDir "Monaspace.zip"
  $ExtractPath  = Join-Path $TempDir "Monaspace"
  $UserFontsPath = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"

  try {
    New-Item -Path $TempDir -ItemType Directory -Force | Out-Null
    if (-not (Test-Path $UserFontsPath)) {
      New-Item -Path $UserFontsPath -ItemType Directory -Force | Out-Null
    }

    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $FontUrl -OutFile $ZipPath -UseBasicParsing
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force

    $FontFiles = Get-ChildItem -Path $ExtractPath -Include "*.ttf", "*.otf" -Recurse
    foreach ($FontFile in $FontFiles) {
      Copy-Item -Path $FontFile.FullName -Destination (Join-Path $UserFontsPath $FontFile.Name) -Force
    }

    $Shell = New-Object -ComObject Shell.Application
    $FontsFolder = $Shell.Namespace(0x14)
    foreach ($FontFile in $FontFiles) {
      try { $FontsFolder.CopyHere($FontFile.FullName, 0x10) } catch {}
    }

    Write-LogSuccess "Monaspace Nerd Font installed."
  } catch {
    Write-LogWarning "Failed to install Monaspace Nerd Font: $($_.Exception.Message)"
  } finally {
    if (Test-Path $TempDir) { Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue }
  }
}

function Deploy-Dotfiles {
  Write-LogInfo "Deploying dotfiles..."

  $homeSource = Join-Path $DOTFILES_DIR "windows\home"
  if (Test-Path $homeSource) {
    Copy-Item -Path "$homeSource\*" -Destination $env:USERPROFILE -Recurse -Force
  }

  $roamingSource = Join-Path $DOTFILES_DIR "windows\roaming"
  if (Test-Path $roamingSource) {
    $vscodeSource = Join-Path $roamingSource "Code - Insiders\User\settings.json"
    $vscodeDest   = "$env:APPDATA\Code - Insiders\User\settings.json"
    if (Test-Path $vscodeSource) {
      $vscodeDir = Split-Path -Parent $vscodeDest
      if (-not (Test-Path $vscodeDir)) { New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null }
      Copy-Item -Path $vscodeSource -Destination $vscodeDest -Force
    }
  }

  $appdataSource = Join-Path $DOTFILES_DIR "windows\appdata"
  if (Test-Path $appdataSource) {
    $terminalSource = Join-Path $appdataSource "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    $terminalDest   = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path $terminalSource) {
      $terminalDir = Split-Path -Parent $terminalDest
      if (-not (Test-Path $terminalDir)) { New-Item -ItemType Directory -Path $terminalDir -Force | Out-Null }
      Copy-Item -Path $terminalSource -Destination $terminalDest -Force
    }

    $wingetSource = Join-Path $appdataSource "Microsoft\WinGet\Settings\settings.json"
    if (Test-Path $wingetSource) {
      $wingetDests = @(
        (Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Settings\settings.json"),
        (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json")
      )
      foreach ($dest in $wingetDests) {
        $dir = Split-Path -Parent $dest
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Copy-Item -Path $wingetSource -Destination $dest -Force
      }
    }
  }

  Write-LogSuccess "Dotfiles deployed."
}

function Disable-AIFeatures {
  Write-LogInfo "Disabling AI features..."

  # Copilot
  $copilotPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
  if (-not (Test-Path $copilotPath)) { New-Item -Path $copilotPath -Force | Out-Null }
  Set-ItemProperty -Path $copilotPath -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord

  # Bing in taskbar search
  $searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
  Set-ItemProperty -Path $searchPath -Name "BingSearchEnabled"  -Value 0 -Type DWord -ErrorAction SilentlyContinue
  Set-ItemProperty -Path $searchPath -Name "CortanaConsent"     -Value 0 -Type DWord -ErrorAction SilentlyContinue

  # AI-generated content suggestions (Start, taskbar, lock screen)
  $cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
  @(
    "SubscribedContent-338393Enabled",
    "SubscribedContent-353694Enabled",
    "SubscribedContent-353696Enabled",
    "SoftLandingEnabled",
    "SystemPaneSuggestionsEnabled"
  ) | ForEach-Object {
    Set-ItemProperty -Path $cdmPath -Name $_ -Value 0 -Type DWord -ErrorAction SilentlyContinue
  }

  # Input insights (handwriting/typing data collection)
  $inputPath = "HKCU:\Software\Microsoft\InputPersonalization"
  if (-not (Test-Path $inputPath)) { New-Item -Path $inputPath -Force | Out-Null }
  Set-ItemProperty -Path $inputPath -Name "RestrictImplicitInkCollection"  -Value 1 -Type DWord -ErrorAction SilentlyContinue
  Set-ItemProperty -Path $inputPath -Name "RestrictImplicitTextCollection" -Value 1 -Type DWord -ErrorAction SilentlyContinue

  # Advertising ID
  $adPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
  if (-not (Test-Path $adPath)) { New-Item -Path $adPath -Force | Out-Null }
  Set-ItemProperty -Path $adPath -Name "Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue

  # Diagnostic data / CEIP
  $diagPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
  $diagScript = {
    if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection")) {
      New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord
  }
  $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($diagScript.ToString()))
  Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile", "-EncodedCommand", $encoded -Wait

  Write-LogSuccess "AI features disabled."
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

function Main {
  Write-Host "=====================================" -ForegroundColor Cyan
  Write-Host "  Windows Dotfiles Installation"      -ForegroundColor Cyan
  Write-Host "=====================================" -ForegroundColor Cyan
  Write-Host ""

  Test-SystemRequirements
  Install-PackageManagers
  Set-SudoSupport
  Set-WindowsOptionalFeatures
  Install-Applications
  Install-PowerShellModules
  Install-NerdFonts
  Disable-AIFeatures
  Deploy-Dotfiles

  Write-Host ""
  Write-Host "=====================================" -ForegroundColor Cyan
  Write-LogSuccess "Dotfiles installation complete!"
  Write-Host "=====================================" -ForegroundColor Cyan

  if (Confirm-Action "Restart now?") {
    Restart-Computer
  } else {
    Write-LogInfo "A restart may be required."
  }
}

Main

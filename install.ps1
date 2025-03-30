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

# Package lists
$WINGET_APPS = @(
  # --- Core System & Shell ---
  "Microsoft.PowerShell"
  "Microsoft.WindowsTerminal"

  # --- Developer Essentials ---
  "Git.Git"
  "vim.vim"
  "Microsoft.VisualStudioCode"
  "Python.Python.3.13"
  "Python.Launcher"
  "Microsoft.DevHome"
  "Microsoft.Sysinternals"
  "Microsoft.WinDbg"

  # --- Shell Enhancements & Fonts ---
  "DEVCOM.JetBrainsMonoNerdFont"
  "Starship.Starship"
  "junegunn.fzf"
  "ajeetdsouza.zoxide"

  # --- Essential Utilities ---
  "Microsoft.PowerToys"
  "M2Team.NanaZip"
  "Microsoft.PCManager"
  "Microsoft.OneDrive"

  # --- Browsers ---
  "Microsoft.Edge"
  "TheBrowserCompany.Arc"

  # --- Productivity & Notes ---
  "LukiLabs.Craft"

  # --- Security ---
  "AgileBits.1Password"
  "AgileBits.1Password.CLI"

  # --- Communication ---
  "Discord.Discord"
)

# PowerShell module list
$POWERSHELL_MODULES = @(
  # --- Shell Experience ---
  "PSReadLine"
  "Terminal-Icons"
  "PSFzf"
  "posh-git"

  # --- Extended Functionality ---
  "PowerShellForGitHub"
  "PSWindowsUpdate"
  "BurntToast"
)

# System paths to add
$SYSTEM_PATHS = @(
  "C:\Program Files\Vim\vim91"
)

# Git configuration
$GIT_USER_NAME = "AnalogCyan"
$GIT_USER_EMAIL = "git@thayn.me"

# Paths
$DOTFILES_DIR = Get-Location
$POWERSHELL_PROFILE_DIR = Split-Path -Parent $PROFILE
$CONFIG_DIR = Join-Path $env:USERPROFILE ".config"

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

  Write-LogInfo "Checking if $name is already installed..."
  $installedApp = winget list -e --id $name 2>$null

  if ($installedApp -match $name) {
    Write-LogInfo "$name is already installed. Checking for updates..."
    try {
      winget upgrade --accept-package-agreements --accept-source-agreements -e --silent $name
      if ($LASTEXITCODE -ne 0) {
        throw "Winget upgrade command failed for $name with exit code $LASTEXITCODE"
      }
      Write-LogSuccess "Successfully checked/updated $name."
    }
    catch {
      Write-LogWarning "Could not update $name: $($_.Exception.Message)"
    }
  }
  else {
    Write-LogInfo "Installing $name via Windows Package Manager..."
    try {
      winget install --accept-package-agreements --accept-source-agreements -e --silent $name
      if ($LASTEXITCODE -ne 0) {
        throw "Winget install command failed for $name with exit code $LASTEXITCODE"
      }
      Write-LogSuccess "Successfully installed $name."
    }
    catch {
      Write-LogError "Failed to install $name: $($_.Exception.Message)"
    }
  }
}

# Function to manage sudo functionality
function Set-SudoSupport {
  Write-LogInfo "Configuring sudo functionality..."

  $WinVer = [System.Environment]::OSVersion.Version
  $SupportsBuiltInSudo = ($WinVer.Major -eq 10 -and $WinVer.Build -ge 25300) -or ($WinVer.Major -ge 11 -and $WinVer.Build -ge 22631)

  if ($SupportsBuiltInSudo) {
    Write-LogInfo "Built-in sudo is supported on this system."

    if (Get-Command "gsudo" -ErrorAction SilentlyContinue) {
      Write-LogInfo "Uninstalling gsudo..."
      try {
        winget uninstall gsudo --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
          throw "Winget uninstall failed for gsudo with exit code $LASTEXITCODE"
        }
        Write-LogSuccess "gsudo uninstalled."
      }
      catch {
        Write-LogWarning "Could not uninstall gsudo: $($_.Exception.Message)"
      }
    }

    try {
      $SudoEnabled = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo" -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
      if ($SudoEnabled -ne 1) {
        Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile -Command `"reg add 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo' /v 'Enabled' /t REG_DWORD /d 1 /f`"" -Wait -ErrorAction Stop
        Write-LogSuccess "Enabled built-in sudo!"
      }
      else {
        Write-LogInfo "Built-in sudo is already enabled."
      }
    }
    catch {
      Write-LogError "Failed to enable built-in sudo: $($_.Exception.Message)"
    }

    try {
      $SudoMode = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo" -Name "Mode" -ErrorAction SilentlyContinue).Mode
      if ($SudoMode -ne 0) {
        # 0 is inline mode
        Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile -Command `"reg add 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo' /v 'Mode' /t REG_DWORD /d 0 /f`"" -Wait -ErrorAction Stop
        Write-LogSuccess "Set built-in sudo to inline mode!"
      }
      else {
        Write-LogInfo "Built-in sudo is already in inline mode."
      }
    }
    catch {
      Write-LogError "Failed to set built-in sudo mode: $($_.Exception.Message)"
    }
  }
  else {
    Write-LogInfo "Built-in sudo is NOT supported on this version of Windows. Falling back to gsudo."
    if (-not (Get-Command "gsudo" -ErrorAction SilentlyContinue)) {
      Write-LogInfo "Installing gsudo..."
      try {
        winget install gerardog.gsudo --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
          throw "Winget install failed for gsudo with exit code $LASTEXITCODE"
        }
        Write-LogSuccess "gsudo installed."
      }
      catch {
        Write-LogError "Failed to install gsudo: $($_.Exception.Message)"
      }
    }
    else {
      Write-LogInfo "gsudo is already installed."
    }
  }

  Write-LogSuccess "Sudo configuration completed."
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

function Test-SystemRequirements {
  Write-LogInfo "Checking system requirements..."

  $osVersion = [System.Environment]::OSVersion.Version
  if ($osVersion.Major -lt 10 -or ($osVersion.Major -eq 10 -and $osVersion.Build -lt 22000)) {
    Write-LogError "This script requires Windows 11 or newer!"
    exit 1
  }

  $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
  if ($isAdmin) {
    Write-LogError "Script should not be run as administrator! Please run from a non-elevated prompt."
    exit 1
  }

  Write-LogSuccess "System requirements check passed."
}

function Install-PackageManagers {
  Write-LogInfo "Installing package managers..."

  if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    Write-LogInfo "Windows Package Manager (Winget) not found. Installing..."

    try {
      Start-Process "ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1"
      Write-LogInfo "Microsoft Store has been opened to the App Installer page."
      Write-LogInfo "Please install the App Installer (Winget) from the Microsoft Store."

      $confirmation = Confirm-Action "Have you completed the Winget installation from the Microsoft Store? (y/n)"
      if (-not $confirmation) {
        Write-LogWarning "Winget installation was not confirmed. Some features may not work correctly."
      }
      else {
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-LogSuccess "Environment refreshed for this session."
      }
    }
    catch {
      Write-LogError "Failed to open Microsoft Store. Attempting alternative installation method..."

      $apiUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
      $downloadUrl = $null

      try {
        $release = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        $downloadUrl = ($release.assets | Where-Object { $_.name -like "*.msixbundle" }).browser_download_url

        if ($downloadUrl) {
          $tempFile = Join-Path $env:TEMP "WingetInstaller.msixbundle"
          Write-LogInfo "Downloading Winget installer..."
          Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing

          Write-LogInfo "Installing Winget..."
          $installScript = {
            param($Path)
            Add-AppPackage -Path $Path
          }
          $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($installScript.ToString()))
          Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile", "-EncodedCommand", $encodedCommand, "-Path", $tempFile -Wait

          $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

          Remove-Item $tempFile -Force
          Write-LogSuccess "Winget installed successfully via GitHub release."
        }
        else {
          Write-LogError "Could not find Winget download URL from GitHub API."
        }
      }
      catch {
        Write-LogError "Failed to install Winget via GitHub: $($_.Exception.Message)"
        Write-LogWarning "Please install Winget manually from the Microsoft Store or GitHub."
      }
    }

    if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
      Write-LogSuccess "Winget is now available in this session."
    }
    else {
      Write-LogError "Winget installation could not be verified. Please install it manually."
      if (Confirm-Action "Would you like to continue anyway? Some features may not work. (y/n)") {
        Write-LogWarning "Continuing without verified Winget installation."
      }
      else {
        exit 1
      }
    }
  }
  else {
    Write-LogInfo "Windows Package Manager (Winget) is already installed."
  }

  Write-LogSuccess "Package managers installation completed."
}

function Install-Applications {
  Write-LogInfo "Installing applications..."

  Write-LogInfo "Installing Windows Package Manager applications..."
  foreach ($app in $WINGET_APPS) {
    Install-WingetApp -name $app
  }

  Write-LogSuccess "Applications installation completed."
}

function Install-PowerShellModules {
  Write-LogInfo "Installing additional PowerShell modules..."

  Write-LogInfo "Updating PowerShellGet and setting up PSGallery..."
  try {
    if (Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue) {
      Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    }
    Install-Module -Name PowerShellGet -Force -Scope CurrentUser -ErrorAction Stop
    Write-LogSuccess "PowerShellGet updated and PSGallery trusted."
  }
  catch {
    Write-LogWarning "Could not update PowerShellGet or trust PSGallery: $($_.Exception.Message)"
  }

  foreach ($module in $POWERSHELL_MODULES) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
      Write-LogInfo "Installing $module module..."
      try {
        Install-Module -Name $module -Scope CurrentUser -Force -ErrorAction Stop
        Write-LogSuccess "Installed $module."
      }
      catch {
        Write-LogError "Failed to install module $module: $($_.Exception.Message)"
      }
    }
    else {
      Write-LogInfo "$module is already installed."
    }
  }

  Write-LogSuccess "PowerShell modules installation completed."
}

function Install-StarshipPrompt {
  Write-LogInfo "Configuring Starship prompt..."

  if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
    Write-LogInfo "Starship command not found, ensuring it's installed via winget..."
    Install-WingetApp -name "Starship.Starship"
  }

  # Create config directory if it doesn't exist
  if (-not (Test-Path $CONFIG_DIR)) {
    try {
      New-Item -ItemType Directory -Path $CONFIG_DIR -Force -ErrorAction Stop | Out-Null
      Write-LogInfo "Created config directory at $CONFIG_DIR"
    }
    catch {
      Write-LogError "Failed to create config directory at $CONFIG_DIR: $($_.Exception.Message)"
      Write-LogWarning "Cannot configure Starship without config directory."
      return
    }
  }

  # Copy starship.toml from dotfiles repo
  $starshipConfigSource = Join-Path $DOTFILES_DIR "starship.toml"
  $starshipConfigDest = Join-Path $CONFIG_DIR "starship.toml"

  if (Test-Path $starshipConfigSource) {
    try {
      Copy-Item -Path $starshipConfigSource -Destination $starshipConfigDest -Force -ErrorAction Stop
      Write-LogSuccess "Copied starship.toml to $starshipConfigDest"
    }
    catch {
      Write-LogError "Failed to copy starship.toml: $($_.Exception.Message)"
    }
  }
  else {
    Write-LogWarning "starship.toml not found at $starshipConfigSource. Attempting to download fallback."
    try {
      $url = "https://starship.rs/presets/toml/minimal.toml"
      Invoke-WebRequest -Uri $url -OutFile $starshipConfigDest -UseBasicParsing -ErrorAction Stop
      Write-LogSuccess "Downloaded minimal Starship config to $starshipConfigDest"
    }
    catch {
      Write-LogError "Failed to download fallback Starship config: $($_.Exception.Message)"
    }
  }

  Write-LogSuccess "Starship prompt configuration attempted."
}

function Install-DotfilesConfigs {
  Write-LogInfo "Installing dotfiles configurations..."

  # Create PowerShell profile directory if it doesn't exist
  if (-not (Test-Path $POWERSHELL_PROFILE_DIR)) {
    try {
      New-Item -ItemType Directory -Path $POWERSHELL_PROFILE_DIR -Force -ErrorAction Stop | Out-Null
      Write-LogInfo "Created PowerShell profile directory."
    }
    catch {
      Write-LogError "Failed to create PowerShell profile directory: $($_.Exception.Message)"
    }
  }

  # Copy PowerShell profile
  $sourcePSProfile = Join-Path $DOTFILES_DIR "Windows\Microsoft.PowerShell_profile.ps1"
  if (Test-Path $sourcePSProfile) {
    Write-LogInfo "Installing PowerShell profile..."
    try {
      Copy-Item -Path $sourcePSProfile -Destination $PROFILE -Force -ErrorAction Stop
      Write-LogSuccess "PowerShell profile installed."
    }
    catch {
      Write-LogError "Failed to copy PowerShell profile: $($_.Exception.Message)"
    }
  }
  else {
    Write-LogWarning "PowerShell profile not found at $sourcePSProfile"
  }

  # Copy Windows Terminal settings
  $terminalSettingsSource = Join-Path $DOTFILES_DIR "Windows\Terminal\settings.json"
  $terminalSettingsDestination = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

  if (Test-Path $terminalSettingsSource) {
    Write-LogInfo "Installing Windows Terminal settings..."
    $terminalSettingsDir = Split-Path -Parent $terminalSettingsDestination
    # Create destination directory if it doesn't exist
    if (-not (Test-Path $terminalSettingsDir)) {
      try {
        New-Item -ItemType Directory -Path $terminalSettingsDir -Force -ErrorAction Stop | Out-Null
        Write-LogInfo "Created Windows Terminal settings directory."
      }
      catch {
        Write-LogError "Failed to create Windows Terminal settings directory: $($_.Exception.Message)"
      }
    }
    if (Test-Path $terminalSettingsDir) {
      try {
        Copy-Item -Path $terminalSettingsSource -Destination $terminalSettingsDestination -Force -ErrorAction Stop
        Write-LogSuccess "Windows Terminal settings installed."
      }
      catch {
        Write-LogError "Failed to copy Windows Terminal settings: $($_.Exception.Message)"
      }
    }
  }
  else {
    Write-LogWarning "Windows Terminal settings not found at $terminalSettingsSource"
  }

  # Copy winget settings
  $wingetSettingsSource = Join-Path $DOTFILES_DIR "Windows\winget\settings.json"
  $wingetSettingsDestination = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Settings\settings.json"

  if (Test-Path $wingetSettingsSource) {
    Write-LogInfo "Installing winget settings..."
    $wingetSettingsDir = Split-Path -Parent $wingetSettingsDestination
    # Create destination directory if it doesn't exist
    if (-not (Test-Path $wingetSettingsDir)) {
      try {
        New-Item -ItemType Directory -Path $wingetSettingsDir -Force -ErrorAction Stop | Out-Null
        Write-LogInfo "Created winget settings directory."
      }
      catch {
        Write-LogError "Failed to create winget settings directory: $($_.Exception.Message)"
      }
    }
    if (Test-Path $wingetSettingsDir) {
      try {
        Copy-Item -Path $wingetSettingsSource -Destination $wingetSettingsDestination -Force -ErrorAction Stop
        Write-LogSuccess "Winget settings installed."
      }
      catch {
        Write-LogError "Failed to copy winget settings: $($_.Exception.Message)"
      }
    }
  }
  else {
    Write-LogWarning "Winget settings not found at $wingetSettingsSource"
  }

  Write-LogSuccess "Dotfiles configurations installation attempted."
}

function Set-GitConfiguration {
  Write-LogInfo "Configuring Git..."

  if (Get-Command git -ErrorAction SilentlyContinue) {
    # Choose appropriate editor
    $editor = if (Get-Command code -ErrorAction SilentlyContinue) {
      "code --wait"
    }
    else {
      "vim"
    }

    # Set Git configuration
    try {
      git config --global core.editor $editor
      git config --global user.name $GIT_USER_NAME
      git config --global user.email $GIT_USER_EMAIL
      Write-LogSuccess "Git configuration completed (user.name, user.email, core.editor)."
    }
    catch {
      Write-LogError "Failed to set Git configuration: $($_.Exception.Message)"
    }
  }
  else {
    Write-LogWarning "Git is not installed. Cannot configure Git."
  }
}

function Install-SSHConfig {
  Write-LogInfo "Setting up SSH configuration..."

  $sshPath = Join-Path $env:USERPROFILE ".ssh"

  # Create .ssh directory if it doesn't exist
  if (-not (Test-Path $sshPath)) {
    try {
      New-Item -ItemType Directory -Path $sshPath -Force -ErrorAction Stop | Out-Null
      Write-LogInfo "Created SSH directory at $sshPath"
    }
    catch {
      Write-LogError "Failed to create SSH directory: $($_.Exception.Message)"
      Write-LogWarning "Cannot proceed with SSH configuration without directory."
      return
    }
  }

  # TODO: Implement SSH key copy or generation logic here
  $sshConfigSource = Join-Path $DOTFILES_DIR "Windows\ssh\config"
  $sshConfigDest = Join-Path $sshPath "config"
  if (Test-Path $sshConfigSource) {
    Write-LogInfo "Copying SSH config file..."
    try {
      Copy-Item -Path $sshConfigSource -Destination $sshConfigDest -Force -ErrorAction Stop
      Write-LogSuccess "SSH config copied."
    }
    catch {
      Write-LogError "Failed to copy SSH config: $($_.Exception.Message)"
    }
  }
  else {
    Write-LogInfo "No SSH config found in dotfiles repo at $sshConfigSource. Skipping copy."
  }

  Write-LogSuccess "SSH configuration setup attempted."
}

function Set-SystemPaths {
  Write-LogInfo "Configuring system paths..."

  foreach ($path in $SYSTEM_PATHS) {
    if (Test-Path $path) {
      # Get current Machine PATH, split into an array, trim whitespace, remove empty entries
      $currentPaths = ([Environment]::GetEnvironmentVariable("Path", "Machine") -split ';').Trim() | Where-Object { $_ }

      if ($path -notin $currentPaths) {
        Write-LogInfo "Adding $path to system PATH..."
        $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $newPath = if ([string]::IsNullOrEmpty($machinePath) -or $machinePath.EndsWith(';')) {
          $machinePath + $path
        }
        else {
          $machinePath + ";" + $path
        }
        try {
          $command = "[Environment]::SetEnvironmentVariable('Path', `"$newPath`", 'Machine')"
          Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -Command $command" -Wait -ErrorAction Stop
          Write-LogSuccess "Added $path to system PATH (requires restart/re-login to take full effect)."
          $env:Path += ";$path"
        }
        catch {
          Write-LogError "Failed to add $path to system PATH. Error: $($_.Exception.Message)"
        }
      }
      else {
        Write-LogInfo "$path is already in system PATH"
      }
    }
    else {
      Write-LogWarning "Path $path does not exist, skipping..."
    }
  }

  Write-LogSuccess "System paths configuration completed."
}

function Set-WindowsOptionalFeatures {
  Write-LogInfo "Configuring Windows Optional Features..."

  # Features to disable
  $featuresToDisable = @(
    "WindowsMediaPlayer"
    "MicrosoftWindowsPowerShellV2"
    "MicrosoftWindowsPowerShellV2Root"
  )

  # Features to enable
  $featuresToEnable = @(
    "VirtualMachinePlatform"
    "HypervisorPlatform"
  )

  # Create a script block with the commands that need elevation
  $featureScript = {
    param($DisableList, $EnableList)

    Import-Module Dism

    Write-Output "Disabling unnecessary features..."
    foreach ($feature in $DisableList) {
      Write-Output "Checking feature: $feature"
      $status = Get-WindowsOptionalFeature -Online -FeatureName $feature
      if ($status.State -eq [Microsoft.Dism.Commands.FeatureState]::Enabled) {
        Write-Output "Disabling $feature..."
        Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 3010) {
          # 3010 = Success, restart required
          Write-Warning "Failed to disable $feature (Exit code: $LASTEXITCODE)"
        }
        else {
          Write-Output "$feature disabled (or already disabled)."
        }
      }
      else {
        Write-Output "$feature is already disabled."
      }
    }

    Write-Output "Enabling required features..."
    foreach ($feature in $EnableList) {
      Write-Output "Checking feature: $feature"
      $status = Get-WindowsOptionalFeature -Online -FeatureName $feature
      if ($status.State -eq [Microsoft.Dism.Commands.FeatureState]::Disabled) {
        Write-Output "Enabling $feature..."
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 3010) {
          # 3010 = Success, restart required
          Write-Warning "Failed to enable $feature (Exit code: $LASTEXITCODE)"
        }
        else {
          Write-Output "$feature enabled (or already enabled)."
        }
      }
      else {
        Write-Output "$feature is already enabled."
      }
    }
  }

  # Convert the script block to a Base64 string for elevation
  $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($featureScript.ToString()))

  # Prepare arguments for the elevated process
  $arguments = @(
    "-NoProfile",
    "-EncodedCommand", $encodedCommand,
    "-DisableList", ($featuresToDisable -join ','),
    "-EnableList", ($featuresToEnable -join ',')
  )

  # Execute the commands with elevation
  Write-LogInfo "Requesting elevation to modify Windows features..."
  try {
    Start-Process powershell -Verb RunAs -ArgumentList $arguments -Wait -ErrorAction Stop
    Write-LogSuccess "Windows Optional Features configuration completed (check output above for details)."
  }
  catch {
    Write-LogError "Failed to run elevated process for Windows Features: $($_.Exception.Message)"
  }
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
  Write-Host "This script assumes the user is running a fresh up-to-date Windows installation." -ForegroundColor $COLOR_YELLOW
  Write-Host "Please ensure you have backed up all important data before running this script." -ForegroundColor $COLOR_YELLOW
  Read-Host -Prompt "Press Enter to continue or Ctrl+C to cancel"

  # Run installation steps
  Test-SystemRequirements
  Set-SudoSupport
  Set-WindowsOptionalFeatures
  Install-PackageManagers
  Install-Applications
  Install-PowerShellModules
  Set-SystemPaths
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
  Write-LogSuccess "Dotfiles installation script finished!"
  Write-Host "Some changes (like system PATH updates or Windows Features)" -ForegroundColor $COLOR_YELLOW
  Write-Host "may require a system restart to take full effect." -ForegroundColor $COLOR_YELLOW
  Write-Host "=====================================" -ForegroundColor Cyan

  if (Confirm-Action "Would you like to restart your computer now?") {
    Write-LogInfo "Restarting system..."
    Restart-Computer -Force
  }
  else {
    Write-LogInfo "No restart selected. Please restart manually when convenient."
  }
}

# Execute the installation
Start-Installation

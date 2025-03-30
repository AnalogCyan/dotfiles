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

# Package lists - empty for now, to be populated later
$WINGET_APPS = @(
  "DEVCOM.JetBrainsMonoNerdFont"
  "Microsoft.PowerShell"
  "Microsoft.WindowsTerminal"
  "Microsoft.Edge"
  "Microsoft.PCManager"
  "M2Team.NanaZip"
  "Microsoft.OneDrive"
  "Git.Git"
  "Microsoft.PowerToys"
  "Microsoft.VisualStudioCode"
  "Python.Launcher"
  "Python.Python.3.13"
  "Microsoft.DevHome"
  "Starship.Starship"
  "junegunn.fzf"
  "ajeetdsouza.zoxide"
  "TheBrowserCompany.Arc"
  "AgileBits.1Password"
  "AgileBits.1PasswordCLI"
  
)

# Git configuration
$GIT_USER_NAME = "AnalogCyan"
$GIT_USER_EMAIL = "git@thayn.me"

# Paths
$DOTFILES_DIR = Get-Location
$POWERSHELL_PROFILE_DIR = Split-Path -Parent $PROFILE
$CONFIG_DIR = "$env:USERPROFILE\.config"

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
  
  # First check if the app is already installed
  Write-LogInfo "Checking if $name is already installed..."
  $installedApp = winget list -e --id $name 2>$null
  
  if ($installedApp -match $name) {
    Write-LogInfo "$name is already installed. Checking for updates..."
    winget upgrade --accept-package-agreements --accept-source-agreements -e $name
  }
  else {
    Write-LogInfo "Installing $name via Windows Package Manager..."
    winget install --accept-package-agreements --accept-source-agreements -e $name
  }
}

# Function to manage sudo functionality
function Configure-SudoSupport {
  Write-LogInfo "Configuring sudo functionality..."

  # Check Windows version to see if built-in sudo is available
  $WinVer = [System.Environment]::OSVersion.Version
  $SupportsBuiltInSudo = ($WinVer.Major -eq 10 -and $WinVer.Build -ge 25300) -or ($WinVer.Major -ge 11 -and $WinVer.Build -ge 22631)

  if ($SupportsBuiltInSudo) {
    Write-LogInfo "Built-in sudo is supported on this system."
    
    # Check if gsudo is installed and uninstall it
    if (Get-Command "gsudo" -ErrorAction SilentlyContinue) {
      Write-LogInfo "Uninstalling gsudo..."
      winget uninstall gsudo --silent
    }

    # Enable built-in sudo if not already enabled
    $SudoEnabled = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo" -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
    if ($SudoEnabled -ne 1) {
      Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile -Command reg add 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo' /v 'Enabled' /t REG_DWORD /d 1 /f" -Wait
      Write-LogSuccess "Enabled built-in sudo!"
    }
    else {
      Write-LogInfo "Built-in sudo is already enabled."
    }
    
    # Set sudo to inline mode
    $SudoMode = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo" -Name "Mode" -ErrorAction SilentlyContinue).Mode
    if ($SudoMode -ne 0) {
      # 0 is inline mode
      Start-Process powershell -Verb runAs -ArgumentList "-NoLogo -NoProfile -Command reg add 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo' /v 'Mode' /t REG_DWORD /d 0 /f" -Wait
      Write-LogSuccess "Set built-in sudo to inline mode!"
    }
    else {
      Write-LogInfo "Built-in sudo is already in inline mode."
    }
  }
  else {
    Write-LogInfo "Built-in sudo is NOT supported on this version of Windows. Falling back to gsudo."
    if (-not (Get-Command "gsudo" -ErrorAction SilentlyContinue)) {
      Write-LogInfo "Installing gsudo..."
      winget install gerardog.gsudo --silent --accept-package-agreements --accept-source-agreements
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

  # Check Windows version (Windows 11 or newer)
  $osVersion = [System.Environment]::OSVersion.Version
  if ($osVersion.Major -lt 10 -or ($osVersion.Major -eq 10 -and $osVersion.Build -lt 22000)) {
    Write-LogError "This script requires Windows 11 or newer!"
    exit 1
  }

  # Check if running without admin privileges (preferred)
  $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
  if ($isAdmin) {
    Write-LogError "Script should not be run as administrator!"
    exit 1
  }

  Write-LogSuccess "System requirements check passed."
}

function Update-System {
  Write-LogInfo "Updating Windows system..."

  # Check if running as admin
  $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
  
  if (-not $isAdmin) {
    Write-LogInfo "Elevation required for system updates. Requesting admin privileges..."
    
    # Create a script block with the update commands
    $updateScript = {
      # Force an update scan
      Write-Output "Starting Windows update scan..."
      Start-Process -FilePath "UsoClient.exe" -ArgumentList "StartScan" -NoNewWindow -Wait
      
      # Install PSWindowsUpdate if needed
      if (-not(Get-Command Install-WindowsUpdate -ErrorAction SilentlyContinue)) {
        Write-Output "Installing PSWindowsUpdate module..."
        Install-Module -Name PSWindowsUpdate -Scope AllUsers -Force
      }
      Import-Module PSWindowsUpdate
      
      # Install updates
      try {
        Write-Output "Installing Windows updates (excluding drivers)..."
        Install-WindowsUpdate -AcceptAll -IgnoreReboot -MicrosoftUpdate -NotCategory "Drivers" -RecurseCycle 2
      }
      catch {
        Write-Output "Error installing updates: $_"
      }
    }
    
    # Convert the script block to a string command
    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($updateScript.ToString()))
    
    # Use Start-Process to run the command elevated
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile", "-EncodedCommand", $encodedCommand -Wait
  }
  else {
    # Already running as admin, execute directly
    # Force an update scan
    Write-LogInfo "Starting Windows update scan..."
    Start-Process -FilePath "UsoClient.exe" -ArgumentList "StartScan" -NoNewWindow -Wait
    
    # Ensure PSWindowsUpdate is installed system-wide
    if (-not(Get-Command Install-WindowsUpdate -ErrorAction SilentlyContinue)) {
      Write-LogInfo "Installing PSWindowsUpdate module..."
      Install-Module -Name PSWindowsUpdate -Scope AllUsers -Force
    }
    Import-Module PSWindowsUpdate
    
    # Install updates
    try {
      Write-LogInfo "Installing Windows updates (excluding drivers)..."
      Install-WindowsUpdate -AcceptAll -IgnoreReboot -MicrosoftUpdate -NotCategory "Drivers" -RecurseCycle 2 -ErrorAction Stop
    }
    catch {
      Write-LogError "Failed to install updates: $_"
    }
  }
  
  # Check if a reboot is needed
  if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
    Write-LogWarning "A reboot is required to complete updates."
  }
  
  Write-LogSuccess "System update process completed."
}

function Install-PackageManagers {
  Write-LogInfo "Installing package managers..."

  # Install Windows Package Manager (Winget)
  if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    Write-LogInfo "Windows Package Manager (Winget) not found. Installing..."
    
    # Try to install from Microsoft Store first (preferred method)
    try {
      # Use ms-windows-store URI to open Microsoft Store to the App Installer page
      Start-Process "ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1"
      Write-LogInfo "Microsoft Store has been opened to the App Installer page."
      Write-LogInfo "Please install the App Installer (Winget) from the Microsoft Store."
      
      $confirmation = Confirm-Action "Have you completed the Winget installation from the Microsoft Store? (y/n)"
      if (-not $confirmation) {
        Write-LogWarning "Winget installation was not confirmed. Some features may not work correctly."
      }
      else {
        # Refresh environment to detect newly installed Winget
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-LogSuccess "Environment refreshed."
      }
    }
    catch {
      Write-LogError "Failed to open Microsoft Store. Attempting alternative installation method..."
      
      # Alternative method - download the latest release from GitHub
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
          Add-AppPackage -Path $tempFile
          
          # Refresh environment to detect newly installed Winget
          $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
          
          Remove-Item $tempFile -Force
          Write-LogSuccess "Winget installed successfully via GitHub release."
        }
      }
      catch {
        Write-LogError "Failed to install Winget: $_"
        Write-LogWarning "Please install Winget manually from the Microsoft Store."
      }
    }
    
    # Verify installation
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

  Write-LogSuccess "Applications installation completed."
}

function Install-PowerShellModules {
  Write-LogInfo "Installing additional PowerShell modules..."
  $modules = @(
    "PSReadLine", 
    "Terminal-Icons",
    "PSFzf",
    "posh-git", 
    "PowerShellForGitHub", 
    "PSWindowsUpdate", 
    "BurntToast"
  )
  
  foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
      Write-LogInfo "Installing $module module..."
      Install-Module -Name $module -Scope CurrentUser -Force
    }
    else {
      Write-LogInfo "$module is already installed."
    }
  }

  Write-LogSuccess "PowerShell modules installation completed."
}

function Install-StarshipPrompt {
  Write-LogInfo "Configuring Starship prompt..."
    
  # Create config directory if it doesn't exist
  if (-not (Test-Path $CONFIG_DIR)) {
    New-Item -ItemType Directory -Path $CONFIG_DIR -Force | Out-Null
    Write-LogInfo "Created config directory at $CONFIG_DIR"
  }
    
  # Copy starship.toml from dotfiles repo
  $starshipConfigSource = Join-Path $DOTFILES_DIR "starship.toml"
  $starshipConfigDest = Join-Path $CONFIG_DIR "starship.toml"
    
  if (Test-Path $starshipConfigSource) {
    Copy-Item -Path $starshipConfigSource -Destination $starshipConfigDest -Force
    Write-LogSuccess "Copied starship.toml to $starshipConfigDest"
  }
  else {
    Write-LogError "starship.toml not found at $starshipConfigSource"
    Write-LogInfo "Creating fallback configuration..."
    $url = "https://starship.rs/presets/toml/minimal.toml"
    Invoke-WebRequest -Uri $url -OutFile $starshipConfigDest
  }

  # Ensure Starship is installed via winget
  if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
    Write-LogInfo "Installing Starship via winget..."
    winget install --accept-source-agreements --accept-package-agreements -e Starship.Starship
  }

  Write-LogSuccess "Starship prompt configured."
}

function Install-DotfilesConfigs {
  Write-LogInfo "Installing dotfiles configurations..."

  # Create PowerShell profile directory if it doesn't exist
  if (-not (Test-Path $POWERSHELL_PROFILE_DIR)) {
    New-Item -ItemType Directory -Path $POWERSHELL_PROFILE_DIR -Force | Out-Null
  }

  # Copy PowerShell profile
  $sourcePSProfile = Join-Path $DOTFILES_DIR "Windows\Microsoft.PowerShell_profile.ps1"
  if (Test-Path $sourcePSProfile) {
    Write-LogInfo "Installing PowerShell profile..."
    Copy-Item -Path $sourcePSProfile -Destination $PROFILE -Force
  }
  else {
    Write-LogWarning "PowerShell profile not found at $sourcePSProfile"
  }

  # Copy Windows Terminal settings
  $terminalSettingsSource = Join-Path $DOTFILES_DIR "Windows\Terminal\settings.json"
  $terminalSettingsDestination = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
  
  if (Test-Path $terminalSettingsSource) {
    Write-LogInfo "Installing Windows Terminal settings..."
    # Create destination directory if it doesn't exist
    $terminalSettingsDir = Split-Path -Parent $terminalSettingsDestination
    if (-not (Test-Path $terminalSettingsDir)) {
      New-Item -ItemType Directory -Path $terminalSettingsDir -Force | Out-Null
    }
    Copy-Item -Path $terminalSettingsSource -Destination $terminalSettingsDestination -Force
    Write-LogSuccess "Windows Terminal settings installed."
  }
  else {
    Write-LogWarning "Windows Terminal settings not found at $terminalSettingsSource"
  }

  # Copy winget settings
  $wingetSettingsSource = Join-Path $DOTFILES_DIR "Windows\winget\settings.json"
  $wingetSettingsDestination = "%LOCALAPPDATA%\Microsoft\WinGet\Settings.json"
  
  if (Test-Path $wingetSettingsSource) {
    Write-LogInfo "Installing winget settings..."
    # Create destination directory if it doesn't exist
    $wingetSettingsDir = Split-Path -Parent $wingetSettingsDestination
    if (-not (Test-Path $wingetSettingsDir)) {
      New-Item -ItemType Directory -Path $wingetSettingsDir -Force | Out-Null
    }
    Copy-Item -Path $wingetSettingsSource -Destination $wingetSettingsDestination -Force
    Write-LogSuccess "Winget settings installed."
  }
  else {
    Write-LogWarning "Winget settings not found at $wingetSettingsSource"
  }

  Write-LogSuccess "Dotfiles configurations installed."
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

function Set-WindowsOptionalFeatures {
  Write-LogInfo "Configuring Windows Optional Features..."

  # Create a script block with the commands that need elevation
  $featureScript = {
    # Features to disable
    Write-Output "Disabling unnecessary features..."
    Disable-WindowsOptionalFeature -Online -FeatureName "WindowsMediaPlayer" -NoRestart
    Disable-WindowsOptionalFeature -Online -FeatureName "MicrosoftWindowsPowerShellV2" -NoRestart
    Disable-WindowsOptionalFeature -Online -FeatureName "MicrosoftWindowsPowerShellV2Root" -NoRestart

    # Features to enable
    Write-Output "Enabling required features..."
    Enable-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName "HypervisorPlatform" -NoRestart
  }

  # Convert the script block to a Base64 string for elevation
  $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($featureScript.ToString()))
  
  # Execute the commands with elevation
  Write-LogInfo "Requesting elevation to modify Windows features..."
  Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile", "-EncodedCommand", $encodedCommand -Wait

  Write-LogSuccess "Windows Optional Features configuration completed."
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
  Configure-SudoSupport
  Update-System
  Set-WindowsOptionalFeatures
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

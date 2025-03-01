# =============================================================================
#  Core Configuration and Prompt
# =============================================================================

Function Prompt {
  # Define prompt appearance based on context
  $promptColor = "Cyan"
  $promptIcon = "»"
  $homeIcon = "~"
  $prompt = $null
  
  # Check if running as administrator
  $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $promptColor = "Red"
    $promptIcon = "#"
  }
  
  # Version-specific settings
  if ($PSVersionTable.PSVersion.Major -ge 6) {
    # Setup Git integration
    function InitializeGit {
      Import-Module posh-git
      $GitPromptSettings.DefaultPromptPath = ''
      $GitPromptSettings.DefaultPromptSuffix = ''
      $GitPromptSettings.EnableFileStatus = $false
    }
    
    # Ensure posh-git is installed and loaded
    if (-not (Get-Module -Name "posh-git" -ListAvailable)) {
      Write-Host "Installing posh-git module..."
      PowerShellGet\Install-Module posh-git -Scope CurrentUser -AllowPrerelease -Force
    }
    
    if (-not (Get-Module -Name "posh-git")) {
      Import-Module posh-git
      InitializeGit
    }
    
    # Create prompt with current directory and git status
    if ($(Split-Path (Get-Item -Path ".\").FullName -Leaf) -eq $env:USERNAME) {
      $prompt = Write-Prompt `n$homeIcon -ForegroundColor $promptColor
    }
    else {
      $prompt = Write-Prompt `n$(Split-Path (Get-Item -Path ".\").FullName -Leaf) -ForegroundColor $promptColor
    }
    
    # Add git status if available
    $prompt += & $GitPromptScriptBlock
    $prompt += Write-Prompt " $($promptIcon * ($nestedPromptLevel + 1)) "
  }
  
  # Fallback for PowerShell v5 or admin mode
  if (-not $prompt) {
    $prompt = "$(Write-Host `n$(Split-Path (Get-Item -Path '.\').FullName -Leaf) -NoNewline -ForegroundColor $promptColor) $($promptIcon * ($nestedPromptLevel + 1)) "
  }
  
  return $prompt
}

# =============================================================================
#  Tool Initializations
# =============================================================================

# Windows Package Manager Completion
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)
  [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
  $Local:word = $wordToComplete.Replace('"', '""')
  $Local:ast = $commandAst.ToString().Replace('"', '""')
  winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
  }
}

# Chocolatey Integration
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# Terminal Icons
if (-not (Get-Module -Name "Terminal-Icons" -ListAvailable)) {
  Write-Host "Installing Terminal-Icons module..."
  Install-Module -Name Terminal-Icons -Repository PSGallery -Force
}
Import-Module -Name Terminal-Icons

# =============================================================================
#  Aliases and Functions
# =============================================================================

# Define script directory
$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Core aliases
$aliasList = @(
  @{Name = 'adbIP'; TargetPath = "$curDir\functions\adbIP.ps1" },
  @{Name = 'compile'; TargetPath = "$curDir\functions\compile.ps1" },
  @{Name = 'fish'; TargetPath = "$curDir\functions\fish.ps1" },
  @{Name = '~'; TargetPath = "$curDir\functions\home.ps1" },
  @{Name = 'vi'; TargetPath = 'vim' },
  @{Name = 'vim'; TargetPath = "$curDir\functions\vim.ps1" },
  @{Name = 'nano'; TargetPath = "$curDir\functions\nano.ps1" },
  @{Name = 'cd'; TargetPath = "$curDir\functions\cd.ps1"; Options = 'AllScope' },
  @{Name = 'clera'; TargetPath = 'Clear-Host' },
  @{Name = 'lsd'; TargetPath = "$curDir\functions\lsd.ps1" },
  @{Name = 'mosh'; TargetPath = "$curDir\functions\mosh.ps1" },
  @{Name = 'top'; TargetPath = 'btop' },
  @{Name = 'htop'; TargetPath = 'btop' }
)

foreach ($alias in $aliasList) {
  if ($alias.Options) {
    Set-Alias -Name $alias.Name -Value $alias.TargetPath -Option $alias.Options
  }
  else {
    Set-Alias -Name $alias.Name -Value $alias.TargetPath
  }
}

# =============================================================================
#  Console Appearance
# =============================================================================

$host.UI.RawUI.ForegroundColor = "White"
$host.UI.RawUI.BackgroundColor = "Black"
Set-ItemProperty -Path HKCU:\console -Name WindowAlpha -Value 240

# =============================================================================
#  Greeting Function
# =============================================================================

function Show-Greeting {
  param(
    [int]$SleepDuration = 2
  )
  
  # Wait briefly for any startup messages to clear
  if ($SleepDuration -gt 0) {
    Start-Sleep -Seconds $SleepDuration
  }
  
  Clear-Host
  
  # Show system info with neofetch if available
  if (Get-Command neofetch -ErrorAction SilentlyContinue) {
    neofetch
  }
  
  # Show weather information when available
  if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
    $username = $env:USERNAME
    $hour = (Get-Date).Hour
    $greeting = if ($hour -lt 12) { "Good morning" } 
    elseif ($hour -lt 17) { "Good afternoon" }
    else { "Good evening" }
    
    Write-Host -NoNewLine "$greeting, $username! It's currently "
    
    $min = Get-Date '08:00'
    $max = Get-Date '17:30'
    $now = Get-Date
    if ($min.TimeOfDay -le $now.TimeOfDay -and $max.TimeOfDay -ge $now.TimeOfDay) {
      wsl.exe -- curl -s wttr.in/Harrison+Arkansas\?format="%c+%C+%t+%o"
    }
    else {
      wsl.exe -- curl -s wttr.in/Harrison+Arkansas\?format="%m+%C+%t+%o"
    }
    
    # Add a fortune quote if available
    if (wsl.exe -- command -v fortune > /dev/null 2>&1) {
      Write-Host "`nToday's fortune:"
      wsl.exe -- fortune -n 50 -s
    }
  }
  
  Write-Host ""
}

# =============================================================================
#  Initialize Environment
# =============================================================================

# Load any custom functions from separate files
$functionDir = "$curDir\functions"
if (Test-Path $functionDir) {
  Get-ChildItem -Path $functionDir -Filter "*.ps1" | ForEach-Object {
    # Only load functions that aren't already aliased
    if (-not ($aliasList | Where-Object { $_.TargetPath -eq "functions\$($_.Name)" })) {
      # Dot source the function
      . $_.FullName
    }
  }
}

# Display greeting when profile loads
Show-Greeting
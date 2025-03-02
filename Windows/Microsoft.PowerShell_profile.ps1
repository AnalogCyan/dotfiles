# =============================================================================
#  Core Configuration and Prompt
# =============================================================================

# Install Starship if not already installed
if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
  Write-Host "Installing Starship..."
  winget install --id Starship.Starship
  # Refresh PATH
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# Initialize Starship
Invoke-Expression (&starship init powershell)

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
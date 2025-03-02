# =============================================================================
#  Core Configuration and Prompt
# =============================================================================

# Install Starship if not already installed
try {
  if (-not (winget list --exact --id Starship.Starship)) {
    Write-Host "Installing Starship..."
    winget install --id Starship.Starship --silent --accept-source-agreements --accept-package-agreements
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
  }

  # Initialize Starship if available
  if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
  }
  else {
    Write-Host "Warning: Starship not found. Using default prompt." -ForegroundColor Yellow
  }
}
catch {
  Write-Host "Error initializing Starship: $($_.Exception.Message)" -ForegroundColor Red
  Write-Host "Falling back to default prompt." -ForegroundColor Yellow
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

# Terminal Icons
try {
  if (-not (Get-Module -Name "Terminal-Icons" -ListAvailable)) {
    Write-Host "Installing Terminal-Icons module..."
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force -ErrorAction Stop
  }
  Import-Module -Name Terminal-Icons -ErrorAction Stop
}
catch {
  Write-Host "Error loading Terminal-Icons: $($_.Exception.Message)" -ForegroundColor Yellow
}

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
    if (wsl.exe -- command -v fortune) {
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

function prompt {
  $leftPrompt = $(starship prompt) -replace "`n$"
  $rightPrompt = "$(starship module time)"  # Modify this to change right prompt content

  # Get terminal width
  $width = $Host.UI.RawUI.WindowSize.Width

  # Strip ANSI codes from the left prompt to get its actual length
  $leftPromptPlain = $leftPrompt -replace '\e\[[0-9;]*m', ''
  $leftPromptLength = ($leftPromptPlain -split "`n")[-1].Length  # Length of last line

  # Calculate spacing for right prompt
  $spacing = $width - $leftPromptLength - ($rightPrompt.Length + 2)
  if ($spacing -lt 1) { $spacing = 1 }  # Prevent overlap

  # Move cursor to the right position and print the right prompt
  $ansiMoveRight = "`e[${spacing}G"
  "$leftPrompt`n${ansiMoveRight}$rightPrompt "
}

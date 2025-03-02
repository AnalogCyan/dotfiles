# =============================================================================
#  Core Configuration and Prompt
# =============================================================================

# Initialize Starship if available (skip check for installation on startup)
try {
  if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
  }
}
catch {
  Write-Host "Error initializing Starship: $($_.Exception.Message)" -ForegroundColor Red
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

# Lazy-load Terminal-Icons
function Import-TerminalIcons {
  try {
    if (-not (Get-Module -Name "Terminal-Icons" -ListAvailable)) {
      Write-Host "Installing Terminal-Icons module..."
      Install-Module -Name Terminal-Icons -Repository PSGallery -Force -ErrorAction Stop
    }
    Import-Module -Name Terminal-Icons -ErrorAction Stop
    
    # Remove this function since we don't need it anymore
    Remove-Item function:Import-TerminalIcons
  }
  catch {
    Write-Host "Error loading Terminal-Icons: $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

# Create function aliases that will trigger lazy loading
function ll { Import-TerminalIcons; Get-ChildItem @args }
function ls { Import-TerminalIcons; Get-ChildItem @args }
function dir { Import-TerminalIcons; Get-ChildItem @args }

# Define script directory (needed for custom functions)
$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# =============================================================================
#  Aliases and Functions
# =============================================================================

# Core aliases
$aliasList = @(
  # Add your aliases here
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
#  Greeting Function - Optimized
# =============================================================================

function Show-Greeting {
  param(
    [int]$SleepDuration = 0,
    [switch]$Async
  )
  
  # Function to display the actual greeting
  function Display-ActualGreeting {
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
      
      Write-Host "$greeting, $username!"
      
      # Only fetch weather when user explicitly calls Show-Greeting without -Async
      if (-not $usingAsync) {
        Write-Host -NoNewLine "Current weather: "
        try {
          $weatherResult = wsl.exe -- curl -s --connect-timeout 2 wttr.in/Harrison+Arkansas\?format="%c+%C+%t+%o"
          Write-Host $weatherResult
        }
        catch {
          Write-Host "Weather data unavailable"
        }
        
        # Add a fortune quote if available
        try {
          if (wsl.exe -- command -v fortune 2>/dev/null) {
            Write-Host "`nToday's fortune:"
            wsl.exe -- fortune -n 50 -s
          }
        }
        catch {
          # Silent fail for fortune
        }
      }
    }
    
    Write-Host ""
  }
  
  if ($Async) {
    $usingAsync = $true
    # Run the greeting async so PowerShell becomes usable immediately
    Start-Job -ScriptBlock { 
      param($sleepTime)
      Start-Sleep -Seconds $sleepTime
      # Need to re-define the function in the job context
      ${function:Display-ActualGreeting} = $using:function:Display-ActualGreeting
      Display-ActualGreeting
    } -ArgumentList $SleepDuration | Out-Null
  }
  else {
    $usingAsync = $false
    if ($SleepDuration -gt 0) {
      Start-Sleep -Seconds $SleepDuration
    }
    Display-ActualGreeting
  }
}

# =============================================================================
#  Initialize Environment
# =============================================================================

# Function to install Starship if needed (can be called explicitly)
function Install-Starship {
  try {
    if (-not (winget list --exact --id Starship.Starship)) {
      Write-Host "Installing Starship..."
      winget install --id Starship.Starship --silent --accept-source-agreements --accept-package-agreements
      # Refresh PATH
      $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
      Write-Host "Starship installed successfully! Restart your terminal to use it." -ForegroundColor Green
    }
    else {
      Write-Host "Starship is already installed." -ForegroundColor Green
    }
  }
  catch {
    Write-Host "Error installing Starship: $($_.Exception.Message)" -ForegroundColor Red
  }
}

# Load any custom functions from separate files - only if they exist
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

# Display greeting asynchronously when profile loads
Show-Greeting -Async


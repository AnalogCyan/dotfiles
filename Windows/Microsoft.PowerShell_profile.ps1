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

# Import required modules
Import-Module PSReadLine, Terminal-Icons, PSFzf, posh-git, PowerShellForGitHub, PSWindowsUpdate, BurntToast -ErrorAction SilentlyContinue

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

# Initialize Zoxide (smart directory navigation)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# Configure PSFzf
if (Get-Module -Name PSFzf -ListAvailable) {
  # Use PSReadline built-in to search command history with fzf
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
  
  # Set key bindings for directory navigation (Alt+c opens fzf directory browser)
  Set-PsFzfOption -TabExpansion
  
  # Override built-in directory navigation commands
  Set-PSFzfOption -EnableAliasFuzzySetLocation
  Set-PSFzfOption -EnableAliasFuzzyEdit
  Set-PSFzfOption -EnableAliasFuzzyHistory
  Set-PSFzfOption -EnableAliasFuzzyKillProcess
}

# Configure PSReadLine
if (Get-Module -Name PSReadLine -ListAvailable) {
  # Enable history search
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -EditMode Windows
  
  # Set key bindings
  Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

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
#  Weather Function with Caching
# =============================================================================

function Get-Weather {
  param(
    [string]$City = "",
    [switch]$NoCache,
    [int]$CacheDuration = 1800  # 30 minutes
  )
  
  # Configuration
  $configDir = Join-Path $env:USERPROFILE ".config\weather"
  $configFile = Join-Path $configDir "config"
  $cacheFile = Join-Path $configDir "cache"
  
  # Ensure configuration directory exists
  if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
  }
  
  # Load or create configuration
  if (Test-Path $configFile) {
    $cityConfig = Get-Content $configFile -Raw
    if ([string]::IsNullOrEmpty($City) -and $cityConfig -match 'CITY="(.*)"') {
      $City = $matches[1]
    }
  }
  
  # If city isn't specified and not in config, use provided city or try to detect it
  if ([string]::IsNullOrEmpty($City)) {
    try {
      $City = "Harrison+Arkansas" # Default fallback
      
      # Save to config file
      "CITY=`"$City`"" | Out-File -FilePath $configFile -Encoding utf8 -Force
    }
    catch {
      Write-Error "Could not set default city: $($_.Exception.Message)"
      return "Weather unavailable"
    }
  }
  
  # Check if we have a cached result that's still valid
  if ((Test-Path $cacheFile) -and -not $NoCache) {
    $cacheTime = (Get-Item $cacheFile).LastWriteTime
    $currentTime = Get-Date
    $timeSpan = $currentTime - $cacheTime
    
    if ($timeSpan.TotalSeconds -lt $CacheDuration) {
      return Get-Content $cacheFile -Raw
    }
  }
  
  # Fetch the weather
  function Fetch-WeatherData {
    $maxRetries = 3
    $retryCount = 0
    
    while ($retryCount -lt $maxRetries) {
      try {
        # Get weather data with icon, condition, and temperature
        $weatherData = Invoke-RestMethod -Uri "https://wttr.in/${City}?format=%c+%t" -TimeoutSec 5
        
        if (-not [string]::IsNullOrEmpty($weatherData) -and $weatherData -notmatch "Unknown location") {
          # Parse data
          $weatherData = $weatherData.Trim()
          $parts = $weatherData -split "\s+", 2
          $icon = $parts[0]
          $tempC = $parts[1]
          
          # Extract numeric celsius value and convert to Fahrenheit
          if ($tempC -match '([+-]?\d+)') {
            $celsius = [int]$matches[1]
            $fahrenheit = [math]::Round(($celsius * 9 / 5) + 32)
            $result = "$icon ${fahrenheit}°F/${celsius}°C"
            
            # Cache result
            $result | Out-File -FilePath $cacheFile -Encoding utf8 -Force
            return $result
          }
        }
      }
      catch {
        # Continue to retry
      }
      
      $retryCount++
      if ($retryCount -lt $maxRetries) {
        Start-Sleep -Seconds 2
      }
    }
    
    # If we get here, fetching failed
    return $null
  }
  
  $weatherResult = Fetch-WeatherData
  
  # If fetch failed but we have a cache, use it even if expired
  if ($weatherResult -eq $null -and (Test-Path $cacheFile)) {
    return "$(Get-Content $cacheFile -Raw) (cached)"
  }
  elseif ($weatherResult -eq $null) {
    return "Weather data unavailable"
  }
  
  return $weatherResult
}

# =============================================================================
#  Greeting Function - Simplified
# =============================================================================

function Show-Greeting {
  param(
    [int]$SleepDuration = 0
  )
  
  if ($SleepDuration -gt 0) {
    Start-Sleep -Seconds $SleepDuration
  }
  
  Clear-Host
  
  # Show system info with neofetch if available
  if (Get-Command neofetch -ErrorAction SilentlyContinue) {
    neofetch
  }
  
  $username = $env:USERNAME
  $hour = (Get-Date).Hour
  $greeting = if ($hour -lt 12) { "Good morning" } 
  elseif ($hour -lt 17) { "Good afternoon" }
  else { "Good evening" }
  
  Write-Host "$greeting, $username!"
  
  Write-Host -NoNewLine "Current weather: "
  $weather = Get-Weather
  Write-Host $weather
  
  Write-Host ""
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

# Function to install fzf if needed
function Install-Fzf {
  try {
    if (-not (winget list --exact --id junegunn.fzf)) {
      Write-Host "Installing fzf..."
      winget install --id junegunn.fzf --silent --accept-source-agreements --accept-package-agreements
      # Refresh PATH
      $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
      Write-Host "fzf installed successfully!" -ForegroundColor Green
    }
    else {
      Write-Host "fzf is already installed." -ForegroundColor Green
    }
  }
  catch {
    Write-Host "Error installing fzf: $($_.Exception.Message)" -ForegroundColor Red
  }
}

# Function to install zoxide if needed
function Install-Zoxide {
  try {
    if (-not (winget list --exact --id ajeetdsouza.zoxide)) {
      Write-Host "Installing zoxide..."
      winget install --id ajeetdsouza.zoxide --silent --accept-source-agreements --accept-package-agreements
      # Refresh PATH
      $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
      Write-Host "zoxide installed successfully!" -ForegroundColor Green
    }
    else {
      Write-Host "zoxide is already installed." -ForegroundColor Green
    }
  }
  catch {
    Write-Host "Error installing zoxide: $($_.Exception.Message)" -ForegroundColor Red
  }
}

# Function to install PowerShell modules if needed
function Install-RequiredModules {
  $modules = @("PSReadLine", "Terminal-Icons", "PSFzf", "posh-git", "PowerShellForGitHub", "PSWindowsUpdate", "BurntToast")
  foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
      Write-Host "Installing $module module..."
      Install-Module -Name $module -Scope CurrentUser -Force -ErrorAction SilentlyContinue
    }
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

# Display greeting synchronously when profile loads
Show-Greeting


# =============================================================================
#  Optimized PowerShell Profile (Configuration Only)
# =============================================================================
# Goal: Fast loading. Assumes tools/modules are installed separately.

# Define script directory early (needed for custom functions later)
$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# =============================================================================
#  Lazy Module Loading Functions
# =============================================================================
function Import-ModuleIfExists {
  param([string]$Name)
  if (Get-Module -ListAvailable -Name $Name) {
    Import-Module $Name -ErrorAction SilentlyContinue
    return $true
  }
  return $false
}

# =============================================================================
#  Essential Module Imports (Lazy Loading)
# =============================================================================
# Create proxy functions for commonly used module commands
$lazyLoadModules = @{
  'Terminal-Icons' = $false
  'PSFzf'          = $false
  'posh-git'       = $false
}

function Initialize-Module {
  param([string]$Name)
  if (-not $lazyLoadModules[$Name]) {
    Import-ModuleIfExists $Name
    $lazyLoadModules[$Name] = $true
  }
}

# PSReadLine is essential, load it immediately but with optimized settings
if (Import-ModuleIfExists 'PSReadLine') {
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -EditMode Windows
  Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# =============================================================================
#  Deferred External Tool Initialization
# =============================================================================

# Initialize Starship prompt (deferred)
$env:STARSHIP_CACHE = "$env:TEMP\starship"
$starshipInit = {
  if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
  }
}
# Defer starship initialization to when the prompt is first shown
$ExecutionContext.SessionState.InvokeCommand.PreCommandHookOperation = {
  if ($global:StarshipInitialized -ne $true) {
    . $starshipInit
    $global:StarshipInitialized = $true
    # Remove the hook after initialization
    $ExecutionContext.SessionState.InvokeCommand.PreCommandHookOperation = $null
  }
}

# Initialize Zoxide (deferred)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  $env:_ZO_DATA_DIR = "$env:LOCALAPPDATA\zoxide"
  # Create a lightweight z function that will initialize zoxide on first use
  function z {
    param([Parameter(ValueFromRemainingArguments)]$args)
    if (-not $global:ZoxideInitialized) {
      Invoke-Expression (& { (zoxide init powershell | Out-String) })
      $global:ZoxideInitialized = $true
    }
    z @args
  }
}

# =============================================================================
#  Optimized PSFzf Configuration (Lazy Load)
# =============================================================================
function Initialize-FzfConfig {
  if (-not $global:FzfConfigured) {
    Initialize-Module 'PSFzf'
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
        
    # Only set up Tab completion if PSReadLine version supports it
    $psrlVersion = (Get-Module PSReadLine).Version
    if ($psrlVersion -ge [Version]"2.2.0") {
      Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
        param($ast, $tokens)
        if (-not $global:TabExpansionConfigured) {
          Set-PsFzfOption -TabExpansion
          $global:TabExpansionConfigured = $true
        }
        [Microsoft.PowerShell.PSConsoleReadLine]::MenuComplete()
      }
    }
    $global:FzfConfigured = $true
  }
}

# =============================================================================
#  Argument Completers (Deferred)
# =============================================================================

# Register winget completer only when winget is first used
function winget {
  if (-not $global:WingetCompleterRegistered) {
    Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
      param($wordToComplete, $commandAst, $cursorPosition)
      [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.Utf8Encoding]::new()
      $Local:word = $wordToComplete.Replace('"', '""')
      $Local:ast = $commandAst.ToString().Replace('"', '""')
      winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition
    }
    $global:WingetCompleterRegistered = $true
  }
  $ExecutionContext.InvokeCommand.GetCommand('winget', 'Application').Definition @args
}

# =============================================================================
#  Load Custom Functions (On-Demand)
# =============================================================================
$functionDir = Join-Path -Path $curDir -ChildPath "functions"
if (Test-Path $functionDir) {
  Get-ChildItem -Path $functionDir -Filter "*.ps1" | ForEach-Object {
    . $_.FullName
  }
}

Write-Verbose "PowerShell profile loading complete."


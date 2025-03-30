# =============================================================================
#  Optimized PowerShell Profile (Configuration Only)
# =============================================================================
# Goal: Fast loading. Assumes tools/modules are installed separately.

# Define script directory early (needed for custom functions later)
$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# =============================================================================
#  Essential Module Imports (for Interactive Experience)
# =============================================================================
Write-Verbose "Loading essential PowerShell modules..."
Import-Module PSReadLine -ErrorAction SilentlyContinue
Import-Module Terminal-Icons -ErrorAction SilentlyContinue
Import-Module PSFzf -ErrorAction SilentlyContinue
Import-Module posh-git -ErrorAction SilentlyContinue
# NOTE: Other modules (PowerShellForGitHub, PSWindowsUpdate, BurntToast)
# should be auto-loaded by PowerShell 7+ when their commands are first used.

# =============================================================================
#  External Tool Initializations (Can add to load time)
# =============================================================================

# Initialize Starship prompt (Requires external starship.exe call)
Write-Verbose "Initializing Starship prompt..."
try {
  if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
  }
  else {
    Write-Verbose "Starship command not found, skipping init."
  }
}
catch {
  Write-Warning "Error initializing Starship: $($_.Exception.Message)"
}

# Initialize Zoxide (Requires external zoxide.exe call)
Write-Verbose "Initializing Zoxide..."
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  Invoke-Expression (& { (zoxide init powershell | Out-String) })
}
else {
  Write-Verbose "Zoxide command not found, skipping init."
}

# =============================================================================
#  Module Configurations (Run after essential imports)
# =============================================================================

# Configure PSReadLine
Write-Verbose "Configuring PSReadLine..."
if (Get-Module -Name PSReadLine -ListAvailable) {
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -EditMode Windows

  # Set key bindings
  Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}
else {
  Write-Verbose "PSReadLine module not available for configuration."
}

# Configure PSFzf
Write-Verbose "Configuring PSFzf..."
if (Get-Module -Name PSFzf -ListAvailable) {
  # Use PSReadline built-in to search command history with fzf
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

  # Enable fzf for Tab Expansion (requires PSReadline >= 2.2.0)
  # Check if the command exists before setting, to avoid errors on older PSReadline
  if (Get-Command Set-PSReadLineKeyHandler -ParameterName TabExpansionFunction -ErrorAction SilentlyContinue) {
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete -ScriptBlock {
      param($ast, $tokens)
      $completion = [System.Management.Automation.CommandCompletion]::CompleteInput($ast, $tokens, $cursor)
      if ($completion.CompletionMatches.Count -gt 0) {
        Invoke-PSFzfCompletion $completion
      }
      else {
        # Fallback to default completion if no matches from PSFzf
        [Microsoft.PowerShell.PSConsoleReadLine]::Complete()
      }
    }
  }
  else {
    # Fallback for older PSReadline or if TabExpansionFunction parameter isn't available
    Set-PsFzfOption -TabExpansion
  }

  # Override built-in directory navigation commands (Optional, enable if desired)
  # Set-PSFzfOption -EnableAliasFuzzySetLocation
  # Set-PSFzfOption -EnableAliasFuzzyEdit
  # Set-PSFzfOption -EnableAliasFuzzyHistory
  # Set-PSFzfOption -EnableAliasFuzzyKillProcess
}
else {
  Write-Verbose "PSFzf module not available for configuration."
}

# =============================================================================
#  Argument Completers
# =============================================================================

# Windows Package Manager (winget) Completion
# Note: Registration is fast, but actual completion depends on winget speed.
Write-Verbose "Registering winget argument completer..."
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)
  # Ensure UTF8 encoding for winget complete
  $previousInputEncoding = [Console]::InputEncoding
  $previousOutputEncoding = [Console]::OutputEncoding
  [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.Utf8Encoding]::new()
  try {
    $Local:word = $wordToComplete.Replace('"', '""')
    $Local:ast = $commandAst.ToString().Replace('"', '""')
    # Execute winget complete and create completion results
    winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
  }
  finally {
    # Restore previous console encoding
    [Console]::InputEncoding = $previousInputEncoding
    [Console]::OutputEncoding = $previousOutputEncoding
  }
}

# =============================================================================
#  Aliases and Custom Functions (Definitions)
# =============================================================================

# --- Add Aliases Here ---
# Example: Set-Alias -Name ll -Value Get-ChildItem -Option AllScope


# --- Load Custom Functions from Files ---
# Simplified loop: just dot-sources any .ps1 files in the functions dir.
$functionDir = Join-Path -Path $curDir -ChildPath "functions"
if (Test-Path $functionDir) {
  Write-Verbose "Loading custom functions from '$functionDir'..."
  Get-ChildItem -Path $functionDir -Filter "*.ps1" | ForEach-Object {
    try {
      . $_.FullName
      Write-Verbose " -> Loaded function script: $($_.Name)"
    }
    catch {
      Write-Warning "Failed to load function script: $($_.FullName). Error: $($PSItem.Exception.Message)"
    }
  }
}
else {
  Write-Verbose "Custom functions directory not found: '$functionDir'"
}

# =============================================================================
#  Finalization
# =============================================================================
Write-Verbose "PowerShell profile loading complete."
# You can add a final message here if you like, e.g.:
# Write-Host "Welcome back, Cyan!" -ForegroundColor Cyan


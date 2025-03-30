# =============================================================================
#  PowerShell Profile - Standard Initialization
# =============================================================================
# Goal: Reliable setup using standard tool initializations.

# Define script directory early for use in subsequent paths.
$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# =============================================================================
#  Helper Functions
# =============================================================================

# Safely attempts to import a module. Returns $true if successful, $false otherwise.
function Import-ModuleIfExists {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name
  )
  # Check if the module exists first to avoid unnecessary errors during import attempt.
  if (Get-Module -ListAvailable -Name $Name) {
    try {
      Import-Module $Name -ErrorAction Stop
      return $true
    }
    catch {
      Write-Warning "Failed to import module '$Name': $($_.Exception.Message)"
      return $false
    }
  }
  else {
    # Write-Warning "Module '$Name' not found." # Optional: Uncomment if you want this warning
    return $false
  }
}

# =============================================================================
#  Core Module Imports & Configuration (PSReadLine)
# =============================================================================
# PSReadLine is essential and loaded immediately.
if (Import-ModuleIfExists 'PSReadLine') {
  # Configure PSReadLine options for prediction and editing.
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -EditMode Windows
  # Configure key handlers for history search.
  Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}
else {
  Write-Warning "PSReadLine module not found or failed to load. Essential features might be missing."
}

# =============================================================================
#  Standard Tool Initialization
# =============================================================================

# --- Starship Prompt ---
# Initialize Starship if the command exists.
if (Get-Command starship -ErrorAction SilentlyContinue) {
  try {
    # Standard Starship initialization for PowerShell.
    Invoke-Expression (&starship init powershell --print-full-init | Out-String)
  }
  catch {
    Write-Warning "Failed to initialize Starship: $($_.Exception.Message)"
  }
}

# --- Zoxide ---
# Initialize Zoxide if the command exists.
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  try {
    # Standard Zoxide initialization for PowerShell.
    # This typically defines the 'z' function/alias and other helpers.
    Invoke-Expression (&zoxide init powershell --hook prompt | Out-String) # Adjust flags as needed (e.g., --no-aliases)
  }
  catch {
    Write-Warning "Failed to initialize Zoxide: $($_.Exception.Message)"
  }
}

# --- Posh-Git ---
# Import Posh-Git for Git status integration in the prompt.
[void](Import-ModuleIfExists 'posh-git')

# --- Terminal-Icons ---
# Import Terminal-Icons for enhanced file/folder icons in listings.
[void](Import-ModuleIfExists 'Terminal-Icons')

# --- PSFzf ---
# Import and configure PSFzf if available.
if (Import-ModuleIfExists 'PSFzf') {
  try {
    # Configure PSFzf keybindings and options.
    # PSFzf typically hooks into PSReadLine upon import/configuration.
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

    # Enable Tab completion if PSReadLine version supports it.
    $psrlVersion = (Get-Module PSReadLine -ErrorAction SilentlyContinue)?.Version
    if ($psrlVersion -ge [Version]"2.2.0") {
      Set-PsFzfOption -TabExpansion
    }
  }
  catch {
    Write-Warning "Failed to configure PSFzf options: $($_.Exception.Message)"
  }
}

# --- Winget Argument Completer ---
# Register Winget's native argument completer if winget exists.
if (Get-Command winget -CommandType Application -ErrorAction SilentlyContinue) {
  try {
    Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
      param($wordToComplete, $commandAst, $cursorPosition)
      # Ensure UTF8 encoding for winget completion compatibility.
      $previousInputEncoding = [Console]::InputEncoding
      $previousOutputEncoding = [Console]::OutputEncoding
      [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.Utf8Encoding]::new()
      # Escape quotes for arguments passed to winget complete.
      $Local:word = $wordToComplete.Replace('"', '""')
      $Local:ast = $commandAst.ToString().Replace('"', '""')
      # Call winget's built-in completer.
      winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition
      # Restore previous console encoding.
      [Console]::InputEncoding = $previousInputEncoding
      [Console]::OutputEncoding = $previousOutputEncoding
    }
  }
  catch {
    Write-Warning "Failed to register Winget argument completer: $($_.Exception.Message)"
  }
}

# =============================================================================
#  Profile Loading Complete
# =============================================================================
Write-Verbose "PowerShell profile loading complete."
# You can add a Write-Host message here if you like.
# Write-Host "Profile loaded." -ForegroundColor Green

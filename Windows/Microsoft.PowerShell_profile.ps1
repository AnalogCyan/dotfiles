# =============================================================================
#  Optimized PowerShell Profile (Configuration Only)
# =============================================================================
# Goal: Fast loading. Assumes tools/modules are installed separately.

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
    return $false
  }
}

# =============================================================================
#  Essential Module Imports (PSReadLine)
# =============================================================================
# PSReadLine is loaded immediately due to its core functionality integration.
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
#  Deferred External Tool Initialization
# =============================================================================

# --- Starship Prompt ---
# Deferred initialization until the first prompt rendering.
$env:STARSHIP_CACHE = Join-Path -Path $env:TEMP -ChildPath "starship"
$starshipInitBlock = {
  # Check if the starship command is available.
  if (Get-Command starship -ErrorAction SilentlyContinue) {
    try {
      # Initialize Starship for PowerShell.
      Invoke-Expression (&starship init powershell --print-full-init)
    }
    catch {
      Write-Warning "Failed to initialize Starship: $($_.Exception.Message)"
    }
  }
}

# Register a PreCommandLookupAction hook to initialize Starship once.
$ExecutionContext.SessionState.InvokeCommand.PreCommandLookupAction = {
  param($CommandName)
  # Check the initialization flag using script scope.
  if ($script:StarshipInitialized -ne $true) {
    . $starshipInitBlock
    $script:StarshipInitialized = $true
    # Remove the hook after successful initialization.
    $ExecutionContext.SessionState.InvokeCommand.PreCommandLookupAction = $null
  }
}

# --- Zoxide ---
# Deferred initialization until the 'z' command is first used.
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  # Set the data directory (optional, often handled by zoxide).
  $env:_ZO_DATA_DIR = Join-Path -Path $env:LOCALAPPDATA -ChildPath "zoxide"

  # Define a proxy function 'z' to handle initialization.
  function z {
    param(
      [Parameter(ValueFromRemainingArguments = $true)]
      $arguments
    )

    # Check if Zoxide has been initialized in this session.
    if ($script:ZoxideInitialized -ne $true) {
      try {
        # Execute the zoxide initialization script.
        Invoke-Expression (&zoxide init powershell --no-aliases --hook prompt) # Adjust flags as needed
        $script:ZoxideInitialized = $true

        # After initialization, zoxide replaces this function.
        # Get the newly defined zoxide command (function or alias).
        $zoxideCmd = Get-Command z -ErrorAction SilentlyContinue
        if ($zoxideCmd) {
          # Execute the actual zoxide command with the original arguments.
          & $zoxideCmd @arguments
        }
        else {
          Write-Warning "Zoxide initialization ran, but the 'z' command is not available."
        }
      }
      catch {
        Write-Warning "Failed to initialize Zoxide: $($_.Exception.Message)"
      }
    }
    else {
      # If already initialized, directly call the zoxide command.
      $zoxideCmd = Get-Command z
      & $zoxideCmd @arguments
    }
  }
}

# =============================================================================
#  PSFzf Configuration (Lazy Load via Keybindings)
# =============================================================================

# Function to initialize PSFzf module and configure options on first use.
function Initialize-Fzf {
  # Prevent redundant initialization.
  if ($script:FzfConfigured -ne $true) {
    if (Import-ModuleIfExists 'PSFzf') {
      try {
        # Configure core PSFzf keybindings.
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

        # Check PSReadLine version for Tab completion support.
        $psrlVersion = (Get-Module PSReadLine -ErrorAction SilentlyContinue)?.Version
        if ($psrlVersion -ge [Version]"2.2.0") {
          Set-PsFzfOption -TabExpansion # Enable FZF for Tab completion
        }

        $script:FzfConfigured = $true # Mark as configured.
        return $true # Indicate success

      }
      catch {
        Write-Warning "Failed to configure PSFzf options: $($_.Exception.Message)"
        # Mark as configured even on failure to prevent repeated attempts.
        $script:FzfConfigured = $true
        return $false # Indicate failure
      }
    }
    else {
      # Module not found or failed to load.
      Write-Warning "PSFzf module not found or failed to load. FZF keybindings will not be functional."
      $script:FzfConfigured = $true # Mark as configured to prevent repeated attempts.
      return $false # Indicate failure
    }
  }
  # Return true if already configured.
  return $true
}

# --- Set up Keybindings to Trigger FZF Initialization ---
# Requires PSReadLine to be loaded.
if (Get-Module -Name PSReadLine) {
  # Ctrl+T - File/Directory Search
  Set-PSReadLineKeyHandler -Key 'Ctrl+t' -ScriptBlock {
    # Initialize FZF if needed, then invoke its function.
    if (Initialize-Fzf) {
      Invoke-PSFzf
    }
  }

  # Ctrl+R - History Search
  Set-PSReadLineKeyHandler -Key 'Ctrl+r' -ScriptBlock {
    # Initialize FZF if needed, then invoke its function.
    if (Initialize-Fzf) {
      Invoke-PSFzfReverseHistorySearch
    }
  }

  # Tab Completion (if PSReadLine version is sufficient)
  $psrlVersion = (Get-Module PSReadLine -ErrorAction SilentlyContinue)?.Version
  if ($psrlVersion -ge [Version]"2.2.0") {
    Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
      param($ast, $tokens)
      # Initialize FZF (which enables TabExpansion via Set-PsFzfOption).
      Initialize-Fzf
      # Call the standard PSReadLine Tab completion function.
      [Microsoft.PowerShell.PSConsoleReadLine]::MenuComplete()
    }
  }
}

# =============================================================================
#  Argument Completers (Deferred - Winget Example)
# =============================================================================

# Check if winget command exists.
if (Get-Command winget -ErrorAction SilentlyContinue) {
  # Define a proxy function for 'winget' to register completer on first use.
  function winget {
    param(
      [Parameter(ValueFromRemainingArguments = $true)]
      $arguments
    )

    # Register the completer only once per session.
    if ($script:WingetCompleterRegistered -ne $true) {
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
        $script:WingetCompleterRegistered = $true
      }
      catch {
        Write-Warning "Failed to register Winget argument completer: $($_.Exception.Message)"
      }
    }

    # Execute the actual winget command.
    $wingetCmd = Get-Command winget -CommandType Application
    & $wingetCmd @arguments
  }
}

# =============================================================================
#  Standard Module Imports (Posh-Git, Terminal-Icons)
# =============================================================================
# These modules are imported directly as lazy-loading provides diminishing returns
# relative to the complexity involved in deferring prompt/formatting hooks.

Import-ModuleIfExists 'posh-git'
Import-ModuleIfExists 'Terminal-Icons'

# =============================================================================
#  Load Custom Functions
# =============================================================================
$functionDir = Join-Path -Path $curDir -ChildPath "functions"
if (Test-Path $functionDir -PathType Container) {
  # Dot-source all .ps1 files found in the functions directory.
  Get-ChildItem -Path $functionDir -Filter "*.ps1" -File | ForEach-Object {
    try {
      . $_.FullName
    }
    catch {
      Write-Warning "Failed to load custom function '$($_.Name)': $($_.Exception.Message)"
    }
  }
}

# =============================================================================
#  Profile Loading Complete
# =============================================================================
# End of profile script.

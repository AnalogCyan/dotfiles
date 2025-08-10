# =============================================================================
#  PowerShell Profile - Standard Initialization (refined)
# =============================================================================
# Goals: fast, interactive-safe, idempotent, Starship-owned prompt

# Interactive guard (skip heavy bits for non-interactive contexts)
$IsInteractive = $Host.Name -like '*Console*' -or $Host.Name -like '*Terminal*'

# Helper: lazy, safe module import
function Import-ModuleIfExists {
  param([Parameter(Mandatory)][string]$Name)
  if (Get-Module -ListAvailable -Name $Name) {
    try { Import-Module $Name -ErrorAction Stop; return $true }
    catch { Write-Warning "Failed to import module '$Name': $($_.Exception.Message)"; return $false }
  }
  return $false
}

# Session quality-of-life (lightweight)
$env:PATH = @("$HOME\bin", $env:PATH) -join ';'  # idempotent-ish prepend
$ProgressPreference = 'SilentlyContinue'         # quieter long commands
$ErrorView = 'ConciseView'                       # readable stack traces (pwsh 7+)

if ($IsInteractive) {

  # ---------------------------
  # PSReadLine (essential)
  # ---------------------------
  if (Import-ModuleIfExists 'PSReadLine') {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
  } else {
    Write-Warning "PSReadLine not found; line editing and history search will be basic."
  }

  # ---------------------------
  # Starship (prompt owner)
  # ---------------------------
  if (Get-Command starship -ErrorAction SilentlyContinue) {
    try {
      # Let Starship own the prompt; no custom prompt functions before this.
      Invoke-Expression (& starship init powershell)
    } catch {
      Write-Warning "Starship init failed: $($_.Exception.Message)"
    }
  }

  # ---------------------------
  # zoxide (directory jumping)
  # Use --hook pwd so it *doesn't* replace the prompt Starship owns.
  # ---------------------------
  if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    try { Invoke-Expression (& zoxide init powershell --hook pwd) }
    catch { Write-Warning "zoxide init failed: $($_.Exception.Message)" }
  }

  # ---------------------------
  # posh-git / Terminal-Icons
  # ---------------------------
  [void](Import-ModuleIfExists 'posh-git')
  [void](Import-ModuleIfExists 'Terminal-Icons')

  # ---------------------------
  # PSFzf (fzf keybinds)
  # ---------------------------
  if (Import-ModuleIfExists 'PSFzf') {
    try {
      Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
      $psrlVersion = (Get-Module PSReadLine -ErrorAction SilentlyContinue)?.Version
      if ($psrlVersion -ge [Version]'2.2.0') { Set-PsFzfOption -TabExpansion }
    } catch {
      Write-Warning "PSFzf configuration failed: $($_.Exception.Message)"
    }
  }

  # ---------------------------
  # Winget native completer (idempotent)
  # ---------------------------
  if (Get-Command winget -CommandType Application -ErrorAction SilentlyContinue) {
    try {
      # Only register if not already present in this session
      $hasCompleter = (Get-CompletionPredictor | Out-Null; $false) 2>$null
      Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        $prevIn  = [Console]::InputEncoding
        $prevOut = [Console]::OutputEncoding
        [Console]::InputEncoding  = [System.Text.Utf8Encoding]::new()
        [Console]::OutputEncoding = [System.Text.Utf8Encoding]::new()
        try {
          $w = $wordToComplete.Replace('"','""')
          $a = $commandAst.ToString().Replace('"','""')
          winget complete --word="$w" --commandline "$a" --position $cursorPosition
        } finally {
          [Console]::InputEncoding  = $prevIn
          [Console]::OutputEncoding = $prevOut
        }
      }
    } catch {
      Write-Warning "Winget completer registration failed: $($_.Exception.Message)"
    }
  }

  # ---------------------------
  # PowerToys Command-Not-Found (if available)
  # ---------------------------
  [void](Import-ModuleIfExists -Name 'Microsoft.WinGet.CommandNotFound')

} # end interactive guard

# Verbose breadcrumb (use `$PSStyle` coloring if you like)
Write-Verbose "PowerShell profile loaded (interactive: $IsInteractive)."

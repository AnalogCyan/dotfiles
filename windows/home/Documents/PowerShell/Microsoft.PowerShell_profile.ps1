# =============================================================================
#  PowerShell Profile
# =============================================================================

$IsInteractive = $Host.Name -like '*Console*' -or $Host.Name -like '*Terminal*'

function Import-ModuleIfExists {
  param([Parameter(Mandatory)][string]$Name)
  if (Get-Module -ListAvailable -Name $Name) {
    try { Import-Module $Name -ErrorAction Stop; return $true }
    catch { Write-Warning "Failed to import module '$Name': $($_.Exception.Message)"; return $false }
  }
  return $false
}

$env:PATH = @("$HOME\bin", $env:PATH) -join ';'
$ProgressPreference = 'SilentlyContinue'
$ErrorView = 'ConciseView'  # pwsh 7+

# Editor
if (Get-Command code-insiders -ErrorAction SilentlyContinue) {
  $env:EDITOR = 'code-insiders --wait -n'
} elseif (Get-Command code -ErrorAction SilentlyContinue) {
  $env:EDITOR = 'code --wait -n'
} elseif (Get-Command hx -ErrorAction SilentlyContinue) {
  $env:EDITOR = 'hx'
} else {
  $env:EDITOR = 'notepad'
}
$env:VISUAL     = $env:EDITOR
$env:GIT_EDITOR = $env:EDITOR

# code-insiders -> code
if (Get-Command code-insiders -ErrorAction SilentlyContinue) {
  Set-Alias -Name code -Value code-insiders -Force
}

# Navigation
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }

# Modern tool aliases
if (Get-Command eza -ErrorAction SilentlyContinue) {
  $ezaParams = '--icons --git --group --group-directories-first --time-style=long-iso --color-scale=all'
  function ls   { Invoke-Expression "eza $ezaParams $args" }
  function ll   { Invoke-Expression "eza --all --header --long $ezaParams $args" }
  function la   { eza -lbhHigUmuSa @args }
  function lt   { Invoke-Expression "eza --tree $ezaParams $args" }
  function tree { Invoke-Expression "eza --tree $ezaParams $args" }
}
if (Get-Command bat -ErrorAction SilentlyContinue) {
  Set-Alias -Name cat -Value bat -Force
}
if (Get-Command rg -ErrorAction SilentlyContinue) {
  Set-Alias -Name grep -Value rg -Force
}
if (Get-Command fd -ErrorAction SilentlyContinue) {
  Set-Alias -Name find -Value fd -Force
}
if (Get-Command hx -ErrorAction SilentlyContinue) {
  Set-Alias -Name vim  -Value hx -Force
  Set-Alias -Name vi   -Value hx -Force
  Set-Alias -Name nano -Value hx -Force
}

if ($IsInteractive) {

  # ---------------------------
  # PSReadLine
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
  # Starship
  # ---------------------------
  if (Get-Command starship -ErrorAction SilentlyContinue) {
    try {
      Invoke-Expression (& starship init powershell)
    } catch {
      Write-Warning "Starship init failed: $($_.Exception.Message)"
    }
  }

  # ---------------------------
  # zoxide
  # ---------------------------
  if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    try {
      Invoke-Expression (& zoxide init powershell --hook pwd)
      Set-Alias -Name cd -Value z -Force
    }
    catch { Write-Warning "zoxide init failed: $($_.Exception.Message)" }
  }

  # ---------------------------
  # posh-git / Terminal-Icons
  # ---------------------------
  [void](Import-ModuleIfExists 'posh-git')
  [void](Import-ModuleIfExists 'Terminal-Icons')

  # ---------------------------
  # PSFzf
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
  # Winget native completer
  # ---------------------------
  if (Get-Command winget -CommandType Application -ErrorAction SilentlyContinue) {
    try {
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
  # PowerToys Command-Not-Found
  # ---------------------------
  [void](Import-ModuleIfExists -Name 'Microsoft.WinGet.CommandNotFound')

}

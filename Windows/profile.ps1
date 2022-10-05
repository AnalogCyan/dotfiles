Function Prompt {
  # If older pwsh version
  if ($PSVersionTable.PSVersion.Major -le 5) {
    $color = "Cyan"
    $promptIcon = ">"
    $prompt = ""
  }
  # If newer pwsh version
  if ($PSVersionTable.PSVersion.Major -ge 6) {
    $color = "Cyan"
    $promptIcon = "»"
    $homeIcon = "~"

    function gitSetup {
      Import-Module posh-git
      $GitPromptSettings.DefaultPromptPath = ''
      $GitPromptSettings.DefaultPromptSuffix = ''
      $GitPromptSettings.EnableFileStatus = $false
    }
    gitSetup
    if (-not (Get-Module -Name "posh-git")) {
      PowerShellGet\Install-Module posh-git -Scope CurrentUser -AllowPrerelease -Force
      gitSetup
    }

    if ($(Split-Path (Get-Item -Path ".\").FullName -Leaf) -eq "cyan") { $prompt = Write-Prompt `n$homeIcon -ForegroundColor $color }
    else { $prompt = Write-Prompt `n$(Split-Path (Get-Item -Path ".\").FullName -Leaf) -ForegroundColor $color }
    $prompt += & $GitPromptScriptBlock
    $prompt += Write-Prompt " $($promptIcon * ($nestedPromptLevel + 1)) "
  }
  # If open as admin
  $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $color = "Red"
    $promptIcon = "#"
    $prompt = ""
  }

  if ($prompt) { "$prompt" } else { "$(Write-Host `n$(Split-Path (Get-Item -Path '.\').FullName -Leaf) -NoNewline -ForegroundColor $color) $($promptIcon * ($nestedPromptLevel + 1)) " }

  # $($executionContext.SessionState.Path.CurrentLocation)
}

# Windows Package Manager
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)
  [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
  $Local:word = $wordToComplete.Replace('"', '""')
  $Local:ast = $commandAst.ToString().Replace('"', '""')
  winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
  }
}

# Chocolatey
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# Terminal-Icons
Import-Module -Name Terminal-Icons

$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Alias adbIP "$curDir\functions\adbIP.ps1"
Set-Alias compile "$curDir\functions\compile.ps1"
Set-Alias fish "$curDir\functions\fish.ps1"
Set-Alias ~ "$curDir\functions\home.ps1"
Set-Alias vi "vim"
Set-Alias vim "$curDir\functions\vim.ps1"
Set-Alias nano "$curDir\functions\nano.ps1"
Set-Alias cd "$curDir\functions\cd.ps1" -Option AllScope
Set-Alias clera Clear-Host
Set-Alias lsd "$curDir\functions\lsd.ps1"
Set-Alias mosh "$curDir\functions\mosh.ps1"

$host.UI.RawUI.ForegroundColor = "White"
$host.UI.RawUI.BackgroundColor = "Black"
Set-ItemProperty -Path HKCU:\console -Name WindowAlpha -Value 240

#Set-Location

Clear-Host

#function shorten-path() {
#  $workingDir = Get-Location | Split-Path -Parent
#  $workingDir += "\"
#  $workingDir += Get-Location | Split-Path -Leaf
#  #$loc = $workingDir.Replace($HOME, '~')
#  # remove prefix for UNC paths
#  $loc = $workingDir -replace '^[^:]+::', ''
#  # make path shorter like tabs in Vim,
#  # handle paths starting with \\ and . correctly
#  return ($loc -replace '\\(\.?)([^\\])[^\\]*(?=\\)', '\$1$2')
#}


#if (Get-Command wsl.exe -errorAction SilentlyContinue) {
#
#  #wsl.exe -- fortune -n 50 -s
#  Write-Host -NoNewLine "Good evening, $env:USERNAME! It's currently ";
#  $min = Get-Date '08:00'
#  $max = Get-Date '17:30'
#  $now = Get-Date
#  if ($min.TimeOfDay -le $now.TimeOfDay -and $max.TimeOfDay -ge $now.TimeOfDay) {
#    wsl.exe -- curl wttr.in/Harrison+Arkansas\?format="%c+%C+%t+%o"
#  }
#  else {
#    wsl.exe -- curl wttr.in/Harrison+Arkansas\?format="%m+%C+%t+%o"
#  }
#}

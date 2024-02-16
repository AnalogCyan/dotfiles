# Initialize oh-my-posh
oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/bubblesline.omp.json' | Invoke-Expression

# Argument completer for Windows Package Manager
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)
  $Encoding = [System.Text.Utf8Encoding]::new()
  [Console]::InputEncoding = $Encoding
  [Console]::OutputEncoding = $Encoding
  
  $Local:word = $wordToComplete.Replace('"', '""')
  $Local:ast = $commandAst.ToString().Replace('"', '""')
  winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
  }
}

# Load Chocolatey Profile if available
$ChocolateyProfile = Join-Path -Path $env:ChocolateyInstall -ChildPath "helpers\chocolateyProfile.psm1"
if (Test-Path $ChocolateyProfile) {
  Import-Module $ChocolateyProfile
}

# Load Terminal-Icons module
Import-Module -Name Terminal-Icons

# Define function aliases
$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$aliasList = @(
  @{Name = 'adbIP'; TargetPath = "functions\adbIP.ps1" },
  @{Name = 'compile'; TargetPath = "functions\compile.ps1" },
  @{Name = 'fish'; TargetPath = "functions\fish.ps1" },
  @{Name = '~'; TargetPath = "functions\home.ps1" },
  @{Name = 'vi'; TargetPath = 'vim' },
  @{Name = 'vim'; TargetPath = "functions\vim.ps1" },
  @{Name = 'nano'; TargetPath = "functions\nano.ps1" },
  @{Name = 'cd'; TargetPath = "functions\cd.ps1"; Options = 'AllScope' },
  @{Name = 'clera'; TargetPath = 'Clear-Host' },
  @{Name = 'lsd'; TargetPath = "functions\lsd.ps1" },
  @{Name = 'mosh'; TargetPath = "functions\mosh.ps1" }
)

foreach ($alias in $aliasList) {
  $aliasName = $alias.Name
  $aliasTarget = Join-Path -Path $curDir -ChildPath $alias.TargetPath
  $aliasOptions = if ($alias.Options) { $alias.Options } else { $null }
  
  Set-Alias -Name $aliasName -Value $aliasTarget -Option $aliasOptions
}

#!TODO: Find replacement for fortune on Windows
# Clear screen and show greeting
Start-Sleep -Seconds 5
Clear-Host
neofetch
Write-Output "It's currently $(Invoke-Expression -Command '~/bin/weather')."
#fortune -n 50 -s
Write-Output

Function Prompt {
  # If open as admin, change prompt.
  $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  ) {
    $color = "Red"
    $promptIcon = "#"
  }
  else {
    $color = "Cyan"
    # » does not display properly on older version of PowerShell
    if ($PSVersionTable.PSVersion.Minor -eq 1) {
      $promptIcon = ">"
    }
    else {
      $promptIcon = "»"
    }
  }

  # Modified to replicate the edan fish_prompt.fish
  "$(Write-Host `n$(Split-Path (Get-Item -Path ".\").FullName -Leaf) -NoNewline -ForegroundColor $color) $($promptIcon * ($nestedPromptLevel + 1)) ";

  # $($executionContext.SessionState.Path.CurrentLocation)
}

$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Alias adbIP "$curDir\functions\adbIP.ps1"
Set-Alias compile "$curDir\functions\compile.ps1"
Set-Alias fish "$curDir\functions\fish.ps1"
Set-Alias ~ "$curDir\functions\home.ps1"
Set-Alias vi "vim"
Set-Alias vim "$curDir\functions\vim.ps1"
Set-Alias cd "$curDir\functions\cd.ps1" -Option AllScope
Set-Alias clera Clear-Host

$host.UI.RawUI.ForegroundColor = "White"
$host.UI.RawUI.BackgroundColor = "Black"
Set-ItemProperty -Path HKCU:\console -Name WindowAlpha -Value 240
Set-Location
Clear-Host
if (Get-Command wsl.exe -errorAction SilentlyContinue) {
  wsl.exe -- fortune -n 50 -s
}
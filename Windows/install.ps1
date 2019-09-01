param(
  [switch]$d = $false
)
if ($d) {
  Write-Output ""
  Write-Output "Windows dependencies can be found at these locations:"
  Write-Output "FiraCode: https://github.com/tonsky/FiraCode/"
  Write-Output "minGW:    https://mingw-w64.org/"
  Write-Output "git:      https://git-scm.com/"
  Write-Output "WSL:      https://docs.microsoft.com/en-us/windows/wsl/install-win10/"
  Write-Output ""
  Write-Output "WSL dependencies can be installed with this command:"
  Write-Output "wsl sudo apt install gcc g++ git vim fish"
  Write-Output ""
  Break
}

function alertUser {
  Write-Output ""
  Write-Output "Installed. You may have to reload the shell for changes to take effect."
  Write-Output "Re-run this script in the future to install updates."
  Write-Output "Please ensure the following tools are also installed:"
  Write-Output "Windows: FiraCode, minGW, git, WSL"
  Write-Output "WSL: gcc/g++, git, vim, fish"
  Write-Output "Re-run this script with the '-d' flag for info on installing the above dependencies."
  Write-Output ""
  Break
}

# Grab directory of script
$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Pass current script to admin console if current console not elevated
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {   
  #Start-Process -WindowStyle hidden powershell -Verb runAs -ArgumentList $curDir\setup.ps1
  #alertUser
  Write-Error -Message "Installer must be run as admin." -Category AuthenticationError
}
# Otherwise, continue as-is
else {
  # Copy files into appropriate windows directory

  $pfunc = Read-Host -Prompt 'Install pwsh profile/functions? (y/N)'
  $ahk = Read-Host -Prompt 'Install ahk scripts? (y/N)'
  $wterm = Read-Host -Prompt 'Install Terminal config? (y/N)'
  
  Set-Location $curDir

  if ($pfunc -eq "y" -or "Y") {
    Copy-Item -Force ".\profile.ps1" -Destination "$env:windir\system32\WindowsPowerShell\v1.0\"

    Copy-Item -Force .\functions -Destination $env:windir\system32\WindowsPowerShell\v1.0\ -Recurse
  }

  if ($ahk -eq "y" -or "Y") {
    Copy-Item -Force '..\..\AutoHotkey\Keyboard Shortcuts\win_tweaks.exe' -Destination "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
  }
  

  if ($wterm -eq "y" -or "Y") {
    Copy-Item -Force '.\profiles.json' -Destination "$env:HOMEPATH\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\RoamingState"
  }
}
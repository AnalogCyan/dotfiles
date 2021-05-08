param(
  [switch]$w = $false,
  $flags
)

# Grab directory of script
$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Output "Before running this script, you should ensure the system is up-to-date."
$a = Read-Host -Prompt 'Close this script and open Windows Update? (Y/n)'
if ($a -ne "n" -or $a -ne "N") {
  Start-Process ms-settings:windowsupdate-action
  exit
}

Write-Output "Enabling virtualization features (Hyper-V, Sandbox, WSL, etc.)..."
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart | Out-Null
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart | Out-Null
Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart | Out-Null
Enable-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -All -NoRestart | Out-Null
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart | Out-Null
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

if (Get-Command chocolatey.exe -ErrorAction SilentlyContinue) {
  Write-Output "Existing Chocolatey install detected, attempting updates..."
  choco upgrade all -y
}
else {
  Write-Output "Installing Chocolatey..."
  Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  refreshenv
}

if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
  Write-Output "Existing winget install detected, attempting updates..."
  winget upgrade --all
}
else {
  Write-Output "Installing winget..."
  New-Item -Force -ItemType Directory -Path ".\tmp"
  Invoke-WebRequest -UseBasicParsing -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.0.Desktop.appx' -OutFile '.\tmp\VCLibs.appx'
  Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/microsoft/winget-cli/releases/download/v-0.3.11102-preview/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle' -OutFile '.\tmp\winget-cli.appxbundle'
  Add-AppxPackage .\tmp\VCLibs.appx
  Add-AppxPackage .\tmp\winget-cli.appxbundle
  refreshenv
}

# Slowly moving installs to winget as it improves
powershell.exe -NoProfile -Command '.\Windows\choco.ps1' ; refreshenv
powershell.exe -NoProfile -Command '.\Windows\winstall.ps1' ; refreshenv
New-Item -Force -ItemType Directory -Path "C:\Users\cyan\AppData\Local\Android"
powershell.exe -NoProfile -Command 'git clone https://github.com/flutter/flutter.git -b stable C:\Users\cyan\AppData\Local\Android'

# C:\Users\cyan\.ssh

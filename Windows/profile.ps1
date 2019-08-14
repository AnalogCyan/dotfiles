$ver = "2.1.1"
$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Alias adbIP "$curDir\functions\adbIP.ps1"
Set-Alias compile "$curDir\functions\compile.ps1"
Set-Alias fish "$curDir\functions\fish.ps1"
Set-Alias ~ "$curDir\functions\home.ps1"
Set-Alias vi "$curDir\functions\vim.ps1"
Set-Alias vim "$curDir\functions\vim.ps1"
# TODO: add some of the useful Linux aliases to Windows as well.

$host.UI.RawUI.ForegroundColor = "White"
$host.UI.RawUI.BackgroundColor = "Black"
Set-ItemProperty -Path HKCU:\console -Name WindowAlpha -Value 240
Set-Location
Clear-Host
Write-Output "Loaded user profile, version $ver."

param( $x )

if (-Not $(Get-Command lolcat -ErrorAction SilentlyContinue)) {
  Write-Warning -Message "lolcat not found, installing..."
  Install-Module -Name lolcat
}
elseif (Get-Command lolcat -ErrorAction SilentlyContinue) {
  ls $x | lolcat
}
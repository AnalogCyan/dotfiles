param( $x )

if (Get-Command g++.exe -errorAction SilentlyContinue) {
  g++ -std=c++11 $x.Replace("\", "/")
}
else {
  Write-Warning -Message "Could not compile for Windows, g++.exe not found!"
}

if (Get-Command wsl.exe -errorAction SilentlyContinue) {
  wsl.exe -- g++ -std=c++11 $x.Replace("\", "/")
}
else {
  Write-Warning -Message "Could not compile for Linux, wsl.exe not found!"
}

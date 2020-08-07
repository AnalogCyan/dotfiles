param( $x )

if (-Not $x) {
  Write-Warning -Message "No input given, assuming ./*.cpp was intended..."
  $x = "./*.cpp"
}

if (Get-Command g++.exe -ErrorAction SilentlyContinue) {
  g++ -std=c++11 $x.Replace("\", "/")
}
else {
  Write-Warning -Message "Could not compile for Windows, g++.exe not found!"
}

if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
  wsl.exe -- g++ -std=c++11 $x.Replace("\", "/")
}
else {
  Write-Warning -Message "Could not compile for Linux, wsl.exe not found!"
}

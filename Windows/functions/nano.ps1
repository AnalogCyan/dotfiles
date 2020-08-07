param( $x )

if (Get-Command nano.exe -ErrorAction SilentlyContinue) {
  if ($x) {
    nano.exe $x
  }
  else {
    nano.exe
  }
}
elseif (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
  if ($x) {
    wsl -- nano $x
  }
  else {
    wsl -- nano
  }
}
else {
  Write-Warning -Message "Failed to open, could not find nano!"
}
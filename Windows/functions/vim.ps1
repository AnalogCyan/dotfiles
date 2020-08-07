param( $x )

if (Get-Command vim.exe -ErrorAction SilentlyContinue) {
  if ($x) {
    vim.exe $x
  }
  else {
    vim.exe
  }
}
elseif (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
  if ($x) {
    wsl -- vim $x
  }
  else {
    wsl -- vim
  }
}
else {
  Write-Warning -Message "Failed to open, could not find vim!"
}
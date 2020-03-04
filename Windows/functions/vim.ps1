param( $x )

if (Get-Command wsl.exe -errorAction SilentlyContinue) {
  if ($x) {
    wsl -- vim $x
  }
  else {
    wsl -- vim
  }
}
elseif (Get-Command vim.exe -errorAction SilentlyContinue) {
  if ($x) {
    vim.exe $x
  }
  else {
    vim.exe
  }
}
else {
  Write-Warning -Message "Could not open, either wsl and/or vim are not installed!"
}
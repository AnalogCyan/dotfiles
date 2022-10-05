param( $x )

if ($x) {
  Set-Location $x
}
else {
  Set-Location $env:HOMEPATH
}
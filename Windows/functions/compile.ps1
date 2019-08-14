# This script attempts to compile programs for both Windows and Linux systems.
param( $x )

function languageDetect {
  if ($x -match '.cpp') {
    return "C++"
  }
  elseif ($x -match '.test') {
    return "Test"
  }
  else {
    Write-Error -Message "Unsupported Language" -Category InvalidArgument
    Exit
  }
}

function pathNormalize {
  return $x.Replace("\", "/")  
}

$lang = languageDetect
$file = pathNormalize

if ($lang -eq 'C++') {
  g++.exe $file
  wsl.exe g++ $file
}
elseif ($lang -eq 'Test') {
  Write-Output "Hello, World!"
  Exit
}

Write-Output "Processed $lang file $file for Windows (.exe) and Linux (.out)."

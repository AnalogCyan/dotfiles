#Requires -RunAsAdministrator

Function Test-CommandExists {
  Param ($command)
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = ‘stop’
  try { if (Get-Command $command) { RETURN $true } }
  Catch { Write-Host “$command does not exist”; RETURN $false }
  Finally { $ErrorActionPreference = $oldPreference }
}

# Ensure spicetify is installed, up-to-date, and configured
if (-not (Test-CommandExists 'spicetify')) {
  Remove-Item -Path "${HOME}/.spicetify" -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -Path "${HOME}/spicetify-cli" -Force -Recurse -ErrorAction SilentlyContinue
  Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1" | Invoke-Expression
  spicetify config prefs_path C:\Users\cyan\AppData\Roaming\Spotify\prefs
  Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1" | Invoke-Expression
  Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/spicetify/spicetify-marketplace/master/install.ps1" | Invoke-Expression
  spicetify
  spicetify backup apply enable-devtool
}
else {
  spicetify config prefs_path C:\Users\cyan\AppData\Roaming\Spotify\prefs
  spicetify upgrade
  spicetify restore backup apply
}
spicetify restore

# Ensure lyrics-plus is installed & up-to-date
spicetify config custom_apps lyrics-plus

# Ensure other extensions are installed & up-to-date
$spicePath = spicetify -c | Split-Path

git clone "https://github.com/Shinyhero36/Spicetify-Taste-Analyzer.git" "${HOME}/spicetify-cli/CustomApps/Spicetify-Taste-Analyzer"
Copy-Item -Path "${HOME}/spicetify-cli/CustomApps/Spicetify-Taste-Analyzer/taste" -Destination "$spicePath/CustomApps" -Recurse -Force
Remove-Item -Path "${HOME}/spicetify-cli/CustomApps/Spicetify-Taste-Analyzer" -Force -Recurse
spicetify config custom_apps taste

git clone "https://github.com/timll/spotify-group-session.git" "${HOME}/spicetify-cli/CustomApps/spotify-group-session"
Copy-Item -Path "${HOME}/spicetify-cli/CustomApps/spotify-group-session/src/group-session.js" -Destination "$spicePath/Extensions" -Recurse -Force
Remove-Item -Path "${HOME}/spicetify-cli/CustomApps/spotify-group-session" -Force -Recurse
spicetify config extensions group-session.js

git clone "https://github.com/huhridge/huh-spicetify-extensions.git" "${HOME}/spicetify-cli/CustomApps/huh-spicetify-extensions"
Copy-Item -Path "${HOME}/spicetify-cli/CustomApps/huh-spicetify-extensions/fullAlbumDate/fullAlbumDate.js" -Destination "$spicePath/Extensions" -Recurse -Force
Copy-Item -Path "${HOME}/spicetify-cli/CustomApps/huh-spicetify-extensions/fullAppDisplayModified/fullAppDisplayMod.js" -Destination "$spicePath/Extensions" -Recurse -Force
Remove-Item -Path "${HOME}/spicetify-cli/CustomApps/huh-spicetify-extensions" -Force -Recurse
spicetify config extensions fullAlbumDate.js
spicetify config extensions fullAppDisplayMod.js

# Ensure Dribbblish Dynamic is installed & up-to-date
Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/JulienMaille/dribbblish-dynamic-theme/master/install.ps1" | Invoke-Expression

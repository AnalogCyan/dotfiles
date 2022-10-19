#!/usr/bin/env pwsh

function InstallLinux {

}

function InstallMacOS {
    
}

function InstallWindows {
    
}

switch ($true) {
    $IsLinux { InstallLinux }
    $IsMacOS { InstallMacOS }
    $IsWindows { InstallWindows }
    Default { Write-Error -Message "Could not determine host operating system." }
}

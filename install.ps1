#!/usr/bin/env pwsh

function InstallLinux {
    if (-Not $(Get-Command "apt")) {
        Write-Error "This script was only designed for debian-based systems. Aborting."
        exit
    }
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

adb kill-server
Start-Sleep -Seconds 2
adb devices
Start-Sleep -Seconds 2

$wifiHost = (get-netconnectionProfile).Name
$wifiClient = adb shell dumpsys netstats | grep -E 'iface=wlan.*networkId' | % {$_.split('"')[1]} | Get-Unique
Start-Sleep -Seconds 2
if ($wifiClient -ne $wifiHost) {
    Write-Output "Cannot connect. Devices are not on same network, or no device was detected."
    exit
}

adb tcpip 5555
Start-Sleep -Seconds 2
$deviceIP = adb shell ip route | awk '{print $9}'
Start-Sleep -Seconds 2
$deviceIP = $deviceIP + ":5555"
Start-Sleep -Seconds 2
adb connect $deviceIP
Start-Sleep -Seconds 2
Write-Output ""
Write-Output "Done. You can now unplug your device."
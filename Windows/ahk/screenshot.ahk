#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


; Simple script for grabbing a screenshot
; and saving it to both the clipboard and screenshots folder.

; Just some notes for future me so I don't forget how this works:
; ^ = control
; ! = alt
; + = shift
; # = windows key
; xxx :: xxx = the double colon signifies remapping the thing before to the thing after

Send #{PrintScreen}
Send !{PrintScreen}
return
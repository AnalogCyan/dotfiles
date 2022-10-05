#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


; A collection of useful tweaks to default Windows behaviours I use.
; Currently mostly just keyboard shortcut tweaks.

; Just some notes for future me so I don't forget how this works:
; ^ = control
; ! = alt
; + = shift
; # = windows key
; xxx :: xxx = the double colon signifies remapping the thing before to the thing after


; Alternate scroll lock key

^CapsLock::
	Send {ScrollLock}
return

; There used to be other tweaks here, but they've since become redundant.
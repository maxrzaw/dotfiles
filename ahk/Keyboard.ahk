; Scripts that do not involve my MX Master 3

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#NoTrayIcon ; Does not show up in the tray
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Make the num pad always on
SetNumLockState, AlwaysOn

; I just enjoy this one SOON™
::soontm::SOON{™} ; Type out "soontm"

; Google Search highlighted text
^+c:: ; use ctrl + Shift + c
{
    Send, ^c
    Sleep 50
    Run, http://www.google.com/search?q=%clipboard%
    Return
}

; Always on Top
; I kept accidentally hitting this, so I disabled it
; ^SPACE::
; {
;     WinSet, AlwaysOnTop, Toggle, A ; ctrl + space
; }


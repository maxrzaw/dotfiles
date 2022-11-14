; Scripts that involve my MX Master 3
; A lot of these are dependent on the specific mappings I made in Logitech Options.
; I mapped one thumb button to screenshot tool (sends Win + Shift + S) and the 
; other thumb button to 'Page Down' since I rarely use that key.

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#NoTrayIcon ; Does not show up in the tray
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Remaps the "snipping tool" output from LogiOptions (LWin + LShift + s) to PrtScn
<#<+s::
    if WinActive("ahk_exe Snagit32.exe")
    {
        ; Cancel the existing screenshot
        Send {Esc}
        WinHide
    }
    else
    {
        ; Take a screenshot
        Send, {PrintScreen}
    }
return

; (Control + Alt + Shift + PgDn) is mapped to the down button in LogiOptions
^!+PgDn::
    if WinActive("ahk_exe Teams.exe")
    {
        ; Mute/Unmute in Teams
        Send ^+m
    }
    else if WinActive("ahk_exe Ssms.exe")
    {
        ; Execute a query in SSMS
        Send {F5}
    }
    else if WinActive("ahk_exe chrome.exe")
    {
        ; Refresh when in Chrome
        Send {F5}
    }
    else if WinActive("ahk_exe mintty.exe")
    {
        ; Paste when in git-bash
        Send {Ins}
    }
    else
    {
        WinGet, Title, ProcessName, A
        MsgBox, The active ProcessName is "%Title%"
    }
return

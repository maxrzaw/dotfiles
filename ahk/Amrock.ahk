; Some scripts specific to my workflows at Amrock

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#NoTrayIcon ; Does not show up in the tray
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; This allows me to Ctrl + RightClick to open a file that I have highlighted in
; SSMS and automatically open it in vscode
; I have noticed that if I have the terminal open in vscode, it will not work.
#IfWinActive, ahk_exe ssms.exe
^RButton::
{
    ; Copy the filename
    Send, ^c
    Sleep, 50

    ; Check if a vscode window is open
    if WinExist("ahk_exe Code.exe")
    {
        WinActivate ; use the window found by WinExist
    }
    else
    {
        ; Open a new instance
        Run, C:\Program Files\Microsoft VS Code\Code.exe
    }

    ; Wait until vscode is open
    WinWaitActive, ahk_exe Code.exe,, 2
    if not ErrorLevel
    {
        ; Open file menu and paste filename and enter
        Send, ^o
        Sleep 1500
        Send, ^v
        Sleep, 50
        Send, {Enter}
    }
    else
    {
        MsgBox, WinWait timed out opening vscode.
        return
    }
}
return
#If ; Reset context

; The VendorNumber for "Max's Test Vendor"
::777::777867651

; Sizes for voting on stories
; Teams was really finicky about timing, that is why there are so many sleeps
::storysizes:: ; Type out "storysizes"
Send Vote with your favorite react:
Sleep 400
SendInput {Enter}
Sleep 300
Send 1
Sleep 200
SendInput {Enter}
Sleep 200
Send 2
Sleep 200
SendInput {Enter}
Sleep 200
Send 3
Sleep 200
SendInput {Enter}
Sleep 200
Send 5
Sleep 200
SendInput {Enter}
Sleep 200
Send 8
Sleep 200
SendInput {Enter}
Sleep 200
Send 13
Sleep 200
SendInput {Enter}
Return
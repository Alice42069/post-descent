#SingleInstance Force
#NoEnv
#Persistent
SetWorkingDir %A_ScriptDir%
SetBatchLines -1
SetWinDelay, -1
SetControlDelay, -1
SetKeyDelay, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0

#include Lib\AHK-ViGEm-Bus.ahk

driverPath := "C:\Program Files\Nefarius Software Solutions\ViGEm Bus Driver"
installerURL := "https://github.com/nefarius/ViGEmBus/releases/download/v1.22.0/ViGEmBus_1.22.0_x64_x86_arm64.exe"
installerFile := A_Temp "\ViGEmBus_Installer.exe"

if !FileExist(driverPath) {
    UrlDownloadToFile, %installerURL%, %installerFile%
    if !FileExist(installerFile) {
        MsgBox, 16, Error, Failed to download the ViGEm installer!
        ExitApp
    }
    Run, %installerFile%, , RunAs
    MsgBox, 64, Info, ViGEm was not installed. The installer has been launched.
    ExitApp
}

controller := new ViGEmXb360()
controller.SubscribeFeedback(Func("OnFeedback"))
OnFeedback(largeMotor, smallMotor, ledNumber) {
}

ShowOverlay() {
    Gui, Show, NoActivate
}
HideOverlay() {
    Gui, Hide
}

Gui, +AlwaysOnTop -Caption +ToolWindow +LastFound +E0x20
Gui, Font, s14 c00FF00 Bold, Consolas
Gui, Add, Text, vStatusText Center w300 h40, Waiting...
Gui, Color, 000000
Gui, +LastFound
WinSet, Transparent, 255
WinSet, TransColor, 000000 255
xPos := (A_ScreenWidth//2) - 150
yPos := 20
Gui, Show, x%xPos% y%yPos% NoActivate, Overlay
Gui, Hide

; --- Toggle sounds true/false here ---
sounds := true

; --- Toggle overlay true/false here ---
overlay := true

sequenceRunning := false
phase := ""

Hotkey, up, Sword_Up, Off
Hotkey, i, Sword_Up, Off
Hotkey, down, Sword_Down, Off
Hotkey, k, Sword_Down, Off
Hotkey, left, Sword_Left, Off
Hotkey, j, Sword_Left, Off
Hotkey, right, Sword_Right, Off
Hotkey, l, Sword_Right, Off

Hotkey, up up, Sword_UpUp, Off
Hotkey, i up, Sword_UpUp, Off
Hotkey, down up, Sword_DownUp, Off
Hotkey, k up, Sword_DownUp, Off
Hotkey, left up, Sword_LeftUp, Off
Hotkey, j up, Sword_LeftUp, Off
Hotkey, right up, Sword_RightUp, Off
Hotkey, l up, Sword_RightUp, Off

; --- Change this key to whatever you want to START the sequence ---
5::StartSequence()

; --- Change this key to whatever you want to STOP or CANCEL the sequence ---
6::StopSequence()
return

StartSequence() {
    global sequenceRunning, phase, sounds, overlay
    if (sequenceRunning)
        return
    sequenceRunning := true
    phase := "waiting"
    if (overlay) {
        GuiControl,, StatusText, Waiting...
        ShowOverlay()
    }
    if (sounds)
        SoundBeep, 1000
    SetTimer, Phase_Revive, -19250
}

StopSequence() {
    global sequenceRunning, phase, controller, sounds, overlay
    sequenceRunning := false
    phase := ""
    controller.Buttons.X.SetState(false)
    controller.Buttons.RB.SetState(false)
    if (overlay)
        HideOverlay()
    if (sounds)
        SoundBeep, 600
    SetTimer, Phase_Revive, Off
    SetTimer, Phase_Swording, Off
    SetTimer, SwordLoop, Off
    DisableSwordingHotkeys()
}

Phase_Revive:
    if (!sequenceRunning)
        return
    if (overlay)
        GuiControl,, StatusText, Reviving...
    controller.Buttons.X.SetState(true)
    SetTimer, End_Revive, -1600
return

End_Revive:
    controller.Buttons.X.SetState(false)
    if (sounds)
        SoundBeep, 500
    if (!sequenceRunning)
        return
    phase := "sword"
    if (overlay) {
        GuiControl,, StatusText, Swording...
        ShowOverlay()
    }
    EnableSwordingHotkeys()
    SetTimer, Phase_Swording, -10
return

Phase_Swording:
    if (!sequenceRunning)
        return
    SetTimer, SwordLoop, 100
    SetTimer, End_Swording, -15000
return

SwordLoop:
    global sequenceRunning, controller
    if (!sequenceRunning) {
        SetTimer, SwordLoop, Off
        controller.Buttons.RB.SetState(false)
        if (overlay)
            HideOverlay()
        DisableSwordingHotkeys()
        return
    }
    controller.Buttons.RB.SetState(true)
    Sleep, 25
    controller.Buttons.RB.SetState(false)
return

End_Swording:
    if (!sequenceRunning)
        return
    SetTimer, SwordLoop, Off
    if (overlay)
        HideOverlay()
    if (sounds)
        SoundBeep, 800
    DisableSwordingHotkeys()
    sequenceRunning := false
return

EnableSwordingHotkeys() {
    Hotkey, up, Sword_Up, On
    Hotkey, i, Sword_Up, On
    Hotkey, down, Sword_Down, On
    Hotkey, k, Sword_Down, On
    Hotkey, left, Sword_Left, On
    Hotkey, j, Sword_Left, On
    Hotkey, right, Sword_Right, On
    Hotkey, l, Sword_Right, On

    Hotkey, up up, Sword_UpUp, On
    Hotkey, i up, Sword_UpUp, On
    Hotkey, down up, Sword_DownUp, On
    Hotkey, k up, Sword_DownUp, On
    Hotkey, left up, Sword_LeftUp, On
    Hotkey, j up, Sword_LeftUp, On
    Hotkey, right up, Sword_RightUp, On
    Hotkey, l up, Sword_RightUp, On
}

DisableSwordingHotkeys() {
    Hotkey, up, Off
    Hotkey, i, Off
    Hotkey, down, Off
    Hotkey, k, Off
    Hotkey, left, Off
    Hotkey, j, Off
    Hotkey, right, Off
    Hotkey, l, Off

    Hotkey, up up, Off
    Hotkey, i up, Off
    Hotkey, down up, Off
    Hotkey, k up, Off
    Hotkey, left up, Off
    Hotkey, j up, Off
    Hotkey, right up, Off
    Hotkey, l up, Off

    controller.Axes.RX.SetState(50)
    controller.Axes.RY.SetState(50)
}

Sword_Up:
    controller.Axes.RY.SetState(100)
return

Sword_Down:
    controller.Axes.RY.SetState(0)
return

Sword_Left:
    controller.Axes.RX.SetState(0)
return

Sword_Right:
    controller.Axes.RX.SetState(100)
return

Sword_UpUp:
Sword_DownUp:
    controller.Axes.RY.SetState(50)
return

Sword_LeftUp:
Sword_RightUp:
    controller.Axes.RX.SetState(50)
return

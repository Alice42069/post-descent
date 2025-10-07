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

active := false
wait := 19250
revive := 1600

; --- Toggle sounds true/false here ---
sounds := true

; --- Toggle overlay true/false here ---
overlay := true

; --- Change this key to whatever you want to toggle ---
5::
    global active, wait, revive, sounds, overlay

    active := true

    if (overlay) {
        GuiControl,, StatusText, Waiting...
        ShowOverlay()
    }

    if (sounds)
        SoundBeep, 1000

    Sleep, wait

    if (overlay)
        GuiControl,, StatusText, Reviving...

    startTime := A_TickCount

    controller.Buttons.X.SetState(true)

    while (A_TickCount - startTime < 15000) {
        controller.Buttons.RB.SetState(true)
        Sleep, 25
        controller.Buttons.RB.SetState(false)
        Sleep, 50

        if (A_TickCount - startTime > revive && overlay)
            GuiControl,, StatusText, Swording...
    }

    controller.Buttons.RB.SetState(false)
    controller.Buttons.X.SetState(false)
    controller.Triggers.RT.SetState(0)
    controller.Axes.RX.SetState(50)
    controller.Axes.RY.SetState(50)

    active := false

    if (sounds)
        SoundBeep, 800

    if (overlay)
        HideOverlay()

return

#If (active)

up::
i::
    controller.Axes.RY.SetState(100)
return

down::
k::
    controller.Axes.RY.SetState(0)
return

left::
j::
    controller.Axes.RX.SetState(0)
return

right::
l::
    controller.Axes.RX.SetState(100)
return

up up::
i up::
down up::
k up::
    controller.Axes.RY.SetState(50)
return

left up::
j up::
right up::
l up::
    controller.Axes.RX.SetState(50)
return

#If
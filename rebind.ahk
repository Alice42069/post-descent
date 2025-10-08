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
installer := A_ScriptDir "\Lib\ViGEmBus_1.22.0_x64_x86_arm64.exe"

if !FileExist(driverPath) {
    if !FileExist(installer) {
        MsgBox, 16, Installer Missing, ViGEm installer not found at:`n%installer%

        ExitApp
    }

    MsgBox, 64, Installing ViGEm Driver, ViGEm Bus driver not found. The installer will run.

    RunWait, %installer%, , RunAs
}

configFile := "settings.ini"
defaultToggleKey := "5"

if !FileExist(configFile) {
    IniWrite, %defaultToggleKey%, %configFile%, Settings, ToggleKey
}

IniRead, toggleKey, %configFile%, Settings, ToggleKey, %defaultToggleKey%

controller := new ViGEmXb360()
controller.SubscribeFeedback(Func("OnFeedback"))
OnFeedback(largeMotor, smallMotor, ledNumber) {
}

global active := false
global togglePressed := false

controller.Buttons.RB.SetState(false)
controller.Buttons.X.SetState(false)
controller.Axes.RX.SetState(50)
controller.Axes.RY.SetState(50)

ShowOverlay() {
    Gui, Show, NoActivate
}
HideOverlay() {
    Gui, Hide
}

Gui, +AlwaysOnTop -Caption +ToolWindow +LastFound +E0x20
Gui, Font, s14 c00FF00 Bold, Consolas
Gui, Add, Text, vStatusText Center w300 h40, Active...
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

Hotkey, %toggleKey%, ToggleActive, Off

Hotkey, %toggleKey%, ToggleActive, On

ToggleActive:
    global active, sounds, overlay, togglePressed

    if (!togglePressed) {
        togglePressed := true
        return
    }

    active := !active

    if (active) {
        if (sounds)
            SoundBeep, 1000

        if (overlay) {
            GuiControl,, StatusText, Active...
            ShowOverlay()
        }
    } else {
        if (sounds)
            SoundBeep, 500

        if (overlay)
            HideOverlay()

        controller.Buttons.RB.SetState(false)
        controller.Buttons.X.SetState(false)
        controller.Axes.RX.SetState(50)
        controller.Axes.RY.SetState(50)
    }

return

#If (active)

f::
    controller.Buttons.RB.SetState(true)
return

f up::
    controller.Buttons.RB.SetState(false)
return

e::
    controller.Buttons.X.SetState(true)
return

e up::
    controller.Buttons.X.SetState(false)
return

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

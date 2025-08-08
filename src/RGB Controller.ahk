; Path config
openrgbPath := "C:\Program Files\OpenRGB\OpenRGB.exe"
powercolorPath := "C:\Program Files (x86)\PowerColor DevilZone\DevilZone.exe"
FileCreateDir, %A_AppData%\RGBController
stateFile := A_AppData "\RGBController\rgb_state.txt"


; Bind Pause key
Pause::
    ; Read or initialize state
    if !FileExist(stateFile) {
        FileAppend, OFF, %stateFile%
        currentState := "OFF"
    } else {
        FileRead, currentState, %stateFile%
        currentState := Trim(currentState)
    }

    if (currentState = "OFF") {
        ; === Switch to DAY MODE ===
        Run, %openrgbPath% --server --profile "All On"
        Sleep, 1
        Run, schtasks /run /tn "DevilZoneElevated", , Hide
	WinRestore, PowerColor RGB
	WinActivate, PowerColor RGB
        WinWaitActive, PowerColor RGB
        Sleep, 1

        ; Set GPU color to 220 0 0
        Click, 1049, 227, 2  ; R
        Send, 220
        Sleep, 1
        Click, 604, 658  ; Apply
        Sleep, 1

        FileDelete, %stateFile%
        FileAppend, ON, %stateFile%
    } else {
        ; === Switch to NIGHT MODE ===
        Run, %openrgbPath% --server --profile "All Off"
        Sleep, 50
        Run, schtasks /run /tn "DevilZoneElevated", , Hide
	WinRestore, PowerColor RGB
	WinActivate, PowerColor RGB
        WinWaitActive, PowerColor RGB
        Sleep, 50

        ; Set GPU color to 0 0 0
        Click, 1049, 227, 2  ; R
        Send, 0
        Sleep, 50
        Click, 604, 658  ; Apply
        Sleep, 50

        FileDelete, %stateFile%
        FileAppend, OFF, %stateFile%
    }

return

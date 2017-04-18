;
; AutoHotkey Version: 1.x
; Language:       English
; Platform:       Win9x/NT
; Author:         A.N.Other <myemail@nowhere.com>
;
; Script Function:
;	Template script (you can customize this template by editing "ShellNew\Template.ahk" in your Windows folder)
;

{	;init
	#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
	SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
	SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
	
	OnExit, exitLabel
	
	clipbak := ""
	debugFileActive := false
	
	ready := false
	validIDE := false
	iniFile := A_WorkingDir . (SubStr(A_WorkingDir, StrLen(A_WorkingDir), 1) != "\" ? "\" : "") . "RWDebugHelper.ini"
	monoFile := "mono.dll"
	
	keyFilePath := "RWMonoPath"
	keyStockFile := "RWMonoStockFile"
	keyDebugFile := "RWMonoDebugFile"
	keyMonoSwitch := "SwapDllsOnDebug"
	keyCodePath := "DebugType"
	keyHotkey := "DebugKey"
	
	codePathsImplemented := {}
	codePathsImplemented.Insert("Xamarin 6")
	codePathsImplemented.Insert("Visual Studio 2017")
	
	;Titles have all spaces replaced with underscores.  Key is an implemented code path from the array above.
	winTitleIDE := {}
	winTitleIDE.Insert("Xamarin_6", "XamarinStudio.exe")
	winTitleIDE.Insert("Visual_Studio_2017", "devenv.exe")
	
	settings := initSettings()
	if (settings)
	{
		;make sure valid code path
		for key, val in codePathsImplemented
		{
			if (val == settings[keyCodePath])
				validIDE := true
		}
		if (!validIDE)
			return
		IDE := settings[keyCodePath]
		StringReplace, IDE, IDE, %A_Space%, _, All
		settings[keyCodePath] := IDE
		
		;try to register the hotkey
		if (!IsLabel(settings[keyCodePath]))
		{
			MsgBox, , RWDebugHelper, % "The code path for " . settings[keyCodePath] . " has not been implemented."
			return
		}
		Hotkey, IfWinActive, % "ahk_exe" . winTitleIDE[settings[keyCodePath]]
		Hotkey, % settings[keyHotkey], % settings[keyCodePath]
	}
	return
}

;Xamarin 6 code path/IDE
Xamarin_6:
{
	winID := "ahk_exe " . winTitleIDE[settings[keyCodePath]]
	handle := WinActive(winID)
	winHandle := "ahk_id " . handle
	
	; NOTE: Xamarin can't be talked to using ANY of the standard windows messaging, not even key events.  Must be 100% click based so sensitive to people rearranging things.  This is based on default layout.
	WinGetPos, , , winWidth, , %winHandle%
	;at full screen 1936 is my width...
	CoordMode, Mouse, Client
	CoordMode, Pixel, Client
	BlockInput, Mouse
	
	MouseClick, Left, 230, 11	; click Build menu item.
	MouseClick, Left, 278, 120	; click Rebuild <project> menu item.
	
	;Wait for the statusbar to indicate build complete.
	
	;Wait for the status bar to turn green...
	statusColor := ""
	while (!isNear(statusColor, "0x9BF6C8", 10))
	{
		Sleep 100
		PixelGetColor, statusColor, % winWidth / 2 - 160, 50 ;x808
	}
	;Wait for the statusbar to go back to grey.
	while (!isNear(statusColor, "0xE5E5E5", 5))
	{
		sleep 100
		PixelGetColor, statusColor, % winWidth / 2 - 160, 50 ;x808
	}
	
	Sleep, 400
	
	;check to see if the statusbar indicates an error state (again using pixel colors...)
	PixelGetColor, statusColor, % winWidth / 2 + 143, 42 ;x1111
	if (isNear(statusColor, "0x4F6DF5", 10))
		return ; don't do anything because the build failed.
	
	; build succeeded, lets swap out the dll and run rimworld
	if (settings[keyMonoSwitch])
	{
		copyCode := 1
		tried := 0
		while (copyCode and tried < 10)
		{
			copyCode := toggleDebugOn()
			if (!copyCode)
				sleep 100
			tried++
		}
		if (copyCode)
		{
			msgbox, , RWDebugHelper, Error number %copyCode% trying to copy the debug mono.dll file.  Ending attempt.
			return
		}
	}

	rwPID := runRimworld()
	
	; now lets engage the soft debugger (ugh)
	MouseClick, Left, 269, 11	;click Run
	Sleep, 100
	MouseClick, Left, 306, 78	;click Run With...
	MouseClick, Left, 675, 74	;click Custom Configuration (opens a dialog)
	Sleep, 500
	MouseClick, Left, 131, 473	;click dropdown for Run Action
	MouseClick, Left, 144, 500	;click Debug -- Custom Command Mono Soft Debugger (assuming user has done what is needed at a previous phase).
	MouseClick, Left, 600, 520	;click Debug button
	;new dialog...
	Sleep, 500
	MouseClick, Left, 152, 80, 3	;tripple click on IP.
	Send, 127.0.0.1
	MouseClick, Left, 152, 107, 3	;tripple click on port.
	Send, 12345
	MouseClick, Left, 526, 175	;click on Connect button
	
	;now we wait for rimworld to close...
	;WinWaitClose, % "ahk_pid " . rwPID
	Process, WaitClose, %rwPID%
	rwPID := 0
	
	;and then restore the mono.dll file to stock.
	if (settings[keyMonoSwitch])
	{
		copyCode := 1
		tried := 0
		while (copyCode and tried < 10)
		{
			copyCode := toggleDebugOff()
			if (!copyCode)
				sleep 100
			tried++
		}
		if (copyCode)
			msgbox, , RWDebugHelper, Error number %copyCode% trying to restore the stock mono.dll file.
	}
	
	return
}

Visual_Studio_2017:
{
	winID := "ahk_exe " . winTitleIDE[settings[keyCodePath]]
	handle := WinActive(winID)
	winHandle := "ahk_id " . handle
	
	; wait for modifier keys be released...
	waitKeyUp("Control")
	waitKeyUp("Alt")
	waitKeyUp("Shift")
	SetKeyDelay, 10, 10 ; useful to specify this, change this one item to change key timings elsewhere.
	
	; initiate rebuild... (ControlSend and WinMenuSelectItem don't work.)
	if (!WinActive(winHandle))
		return
	Send, !b
	Send, r
	if (!WinActive(winHandle))
		return
	
	; sleep for a moment...
	Sleep, 500
	if (!WinActive(winHandle))
		return
	
	; store the clipboard data
	clipbak := Clipboard
	
	; watch for the end of the build...
	buildDone := false
	savedOutput := ""
	while (!buildDone)
	{
		Send, ^!o
		Send, ^a
		Sleep, 50
		if (!WinActive(winHandle))
			break
		Send, ^c
		if (InStr(Clipboard, "=========="))
		{
			savedOutput := Clipboard
			buildDone := true
		}
	}
	
	; retore the clipboard.
	Clipboard := clipback
	clipback := ""
	
	if (!buildDone)
		return
	
	; determine if the build was successful...
	if (!InStr(savedOutput, "0 failed"))
		return
	
	; build succeeded, lets swap out the dll and run rimworld
	if (settings[keyMonoSwitch])
	{
		copyCode := 1
		tried := 0
		while (copyCode and tried < 10)
		{
			copyCode := toggleDebugOn()
			if (!copyCode)
				sleep 100
			tried++
		}
		if (copyCode)
		{
			msgbox, , RWDebugHelper, Error number %copyCode% trying to copy the debug mono.dll file.  Ending attempt.
			return
		}
	}
	
	; run rimworld...
	rwPID := runRimworld()
	
	; start the debug process...
	WinActivate, %winHandle%
	while (!WinActive(winHandle))
		sleep 10
	; Debug -> Attach Unity Debugger
	Send, !d
	Send, {Down}
	Send, {Down}
	Send, {Down}
	Send, {Down}
	Send, {Enter}
	ignoreList := handle
	ignoreList .= "," . waitNewWindow(ignoreList)
	; Input IP
	Send, {Tab}
	Send, {Space}
	waitNewWindow(ignoreList)
	; type in the ip and port...
	Send, {Tab}
	Send, {Tab}
	Send, {Tab}
	Send, 127
	Send, {Tab}
	Send, 0
	Send, {Tab}
	Send, 0
	Send, {Tab}
	Send, 1
	Send, {Tab}
	Send, 12345
	; confirm setting
	Sleep, 100
	Send, {Enter}
	
	;now we wait for rimworld to close...
	;WinWaitClose, % "ahk_pid " . rwPID
	Process, WaitClose, %rwPID%
	
	rwPID := 0
	
	;and then restore the mono.dll file to stock.
	if (settings[keyMonoSwitch])
	{
		copyCode := 1
		tried := 0
		while (copyCode and tried < 10)
		{
			copyCode := toggleDebugOff()
			if (!copyCode)
				sleep 100
			tried++
		}
		if (copyCode)
			msgbox, , RWDebugHelper, Error number %copyCode% trying to restore the stock mono.dll file.
	}
	
	return
}


;general helpers

; comma separated list of window hwnds to ignore.
waitNewWindow(notIDList)
{
	global winID
	
	StringSplit, skipID, notIDList, `,
	found := false
	cur := 0
	while (!found)
	{
		cur := WinActive(winID)
		if (cur = 0)
			continue
		
		hit := false
		Loop, %skipID0%
		{
;			msgbox % "Checking cur: " . cur . "  against " . skipID%A_Index% . " index " . A_Index . " of " . skipID0
			if (cur = skipID%A_Index%)
				hit := true
		}
;		msgbox %cur% hit? %hit%
		if (!hit)
			found := true
		Sleep, 10
	}
;	msgbox found new item: %cur% skip list: %notIDList%
	return cur
}

waitKeyUp(keyName)
{
	while (GetKeyState(keyName))
		Sleep, 10
	return
}

; runs rimworld (with maximized mode as that's my preference, TODO make that a setting.
runRimworld()
{
	global settings
	global keyFilePath
	
	;get the exe file... starting with computing the path from where mono.dll is stored.
	exePath := ""
	ar := StrSplit(settings[keyFilePath], "\")
	for key, val in ar
	{
		if (key < ar.Length() - 2)
			exePath .= val . "\"
	}
	;look for an apt exe file.
	Loop, % exePath . "*.exe"
	{
		if (RegExMatch(A_LoopFileName, "i)rimworld[^.]*\.exe"))
		{
			exeFile := exePath . A_LoopFileName
			break
		}
	}
	
	;set RIMWORLD_MOD_DEBUG=--debugger-agent=transport=dt_socket,address=127.0.0.1:12345,server=y
	EnvSet, RIMWORLD_MOD_DEBUG, --debugger-agent=transport=dt_socket,address=127.0.0.1:12345,server=y
	
	Run, %exeFile%, %exePath%, Max, pid
	
	return pid
}

; copies the debug mono.dll over the Rimworld using verison.
toggleDebugOn()
{
	global settings
	global monoFile
	global keyFilePath
	global keyDebugFile
	global debugFileActive
	
	FileCopy, % settings[keyFilePath] . settings[keyDebugFile], % settings[keyFilePath] . monoFile, 1
	
	debugFileActive := true
	
	return A_LastError
}

; copies the stock mono.dll over the Rimworld using version.
toggleDebugOff()
{
	global settings
	global monoFile
	global keyFilePath
	global keyStockFile
	global debugFileActive
	
	FileCopy, % settings[keyFilePath] . settings[keyStockFile], % settings[keyFilePath] . monoFile, 1
	
	debugFileActive := false
	
	return A_LastError
}

;re color helpers: Because the default SetFormat is decimal, any math operation on a hex number (even if the base type was a string) will convert it.
isNear(c, t, d)
{
	r := "0x" . SubStr(c, 3, 2)
	g := "0x" . SubStr(c, 5, 2)
	b := "0x" . SubStr(c, 7, 2)
	;target values
	tr := "0x" . SubStr(t, 3, 2)
	tg := "0x" . SubStr(t, 5, 2)
	tb := "0x" . SubStr(t, 7, 2)
	;delta values
	dr := r - tr
	dg := g - tg
	db := b - tb
	
	;ToolTip, %dr%   %dg%   %db%
	if (dr < -d or dr > d)
		return false
	if (dg < -d or dg > d)
		return false
	if (db < -d or db > d)
		return false
	return true
}


;mostly settings related functions....

;Handle reading the ini (settings) file and if something is wrong in the process prompt for user input to correct it.
;Will also write the settings file (ie if the file is blank or incomplte or damaged).
initSettings()
{
	global iniFile
	global keyFilePath
	global keyStockFile
	global keyDebugFile
	global keyMonoSwitch
	global keyCodePath
	global keyHotkey
	global monoFile
	
	didWrite := false
	
	err := "ERROR"
	
	keyOrder := {}
	keyOrder.Insert(keyCodePath)
	keyOrder.Insert(keyMonoSwitch)
	keyOrder.Insert(keyHotkey)
	keyOrder.Insert(keyFilePath)
	keyOrder.Insert(keyStockFile)
	keyOrder.Insert(keyDebugFile)
	
	set := {}
	set.Insert(keyMonoSwitch, false)
	set.Insert(keyFilePath, "")
	set.Insert(keyStockFile, "")
	set.Insert(keyDebugFile, "")
	
	def := {}
	def.Insert(keyStockFile, monoFile . ".stock")
	def.Insert(keyDebugFile, monoFile . ".debug")
	def.Insert(keyHotkey, "^F12")
	
	for k, v in keyOrder
	{
		key := v
		val := set[key]
		IniRead, val, %iniFile%, Settings, %key%
		if (key == keyMonoSwitch and (val == err or !isConfirmation(val)))
		{
			MsgBox, % 4+32, RWDebugHelper Auto Swap Dlls on Debug?, RWDebugHelper has the ability to automatically swap between versions of mono.dll when the debug hotkey is pressed.  Would you like the dll to automatically be swapped?
			IfMsgBox, Yes
				val := "Yes"
			else 
				val := "No"
			IniWrite, %val%, %iniFile%, Settings, %key%
			didWrite := true
		}
		if (set[keyMonoSwitch])
		{
			if (key == keyFilePath and (val == err or !InStr(FileExist(val), "D")))
			{
				val := getMonoPath(monoFile)
				IniWrite, %val%, %iniFile%, Settings, %key%
				didWrite := true
			}
			if (key == keyStockFile and (val == err or !FileExist(set[keyFilePath] . val)))
			{
				val := handleFileSelection(monoFile, set[keyFilePath], def[keyStockFile], "stock (not for debugging)")
				if (!val)
					goto subCancelSetup
				IniWrite, %val%, %iniFile%, Settings, %key%
				didWrite := true
			}
			if (key == keyDebugFile and (val == err or !FileExist(set[keyFilePath] . val)))
			{
				val := handleFileSelection(monoFile, set[keyFilePath], def[keyDebugFile], "debug (FOR debugging)")
				if (!val)
					goto subCancelSetup
				IniWrite, %val%, %iniFile%, Settings, %key%
				didWrite := true
			}
		}
		if (key == keyCodePath and val == err)
		{
			val := selectCodePath()
			IniWrite, %val%, %iniFile%, Settings, %key%
			didWrite := true
		}
		if (key == keyHotkey and (val == err or val == ""))
		{
			val := def[key]
			IniWrite, %val%, %iniFile%, Settings, %key%
			didWrite := true
			MsgBox, , RWDebugHelper, By default the hotkey to start debugging is Ctrl+F12.  You will need to edit the ini file to change this, refer to Autohotkey's Hotkeys page.
		}
		set[key] := val . (key == keyFilePath ? "\" : "")
	}
	
	if (didWrite)
		MsgBox, , RWDebugHelper, Your settings have been saved into the file named %iniFile% and can be changed via that file.  To run through the setup process again simply delete that file.
	
	;more code?
	
	return set

	subCancelSetup:
	{
		if (A_IsCompiled != "")
			ExitApp
		else
			return
	}
}

;Presents a dialog for the user to select one of the code paths (IDEs) this app can function with.
selectCodePath()
{
	global codePathsImplemented
	global guiPathChoice
	global guiLongestText
	
	isCanceled := false
	
	;gui setup
	Gui, New, +Hwndme -Resize +Caption -MinimizeBox +OwnDialogs -SysMenu, RWDebugHelper
	Gui, Add, Text, vguiLongestText, Please select a code path (IDE) from the compatible list below.
	GuiControlGet, size, Pos, guiLongestText
	halfSizeW := (sizeW / 2) - 5
	listWorking := ""
	for key, val in codePathsImplemented
	{
		listWorking .= val . "|"
	}
	listWorking := SubStr(listWorking, 1, StrLen(listWorking) -1)
	Gui, Add, DropDownList, w%sizeW% vguiPathChoice Choose1, %listWorking%
	Gui, Add, Button, Default Section w%halfSizeW% gactPathConfirm, OK
	Gui, Add, Button, ys w%halfSizeW% gactPathCancel, Cancel
	Gui, Show
	;pause code while waiting for the user to decide.
	WinWaitClose, ahk_id %me%
	Gui, Destroy ; cleanup
	if (isCanceled)
		return
	return guiPathChoice
	
	;default event...
	GuiEscape:
		goto actPathCancel
	
	;gui actions (ie buttons)
	actPathConfirm:
	{
		Gui, Submit
		return
	}
	
	actPathCancel:
	{
		isCanceled := true
		Gui, Cancel
		return
	}
}

;Handles selection of a file (ie stock or debug) as well as copying and backup operations in preperation for using this tool.
;returns the filename that was selected, not the path.
handleFileSelection(monoFile, dDir, defaultFile, strDetail)
{
	global iniFile
	
	if (FileExist(dDir . monoFile))
	{
		MsgBox, % 3+32, RWDebugHelper, % "Is the " . monoFile . " found in '" . dDir "' the " . strDetail . " dll file?  Canceling will prompt for a backup file."
		doCopy := false
		IfMsgBox, Yes
		{
			; user indicates the selected file IS the stock mono.dll file
			doCopy := true
			sFile := monoFile
			sDir := dDir
		} else {
			;user indicates the file previously selected is NOT the stock mono.dll file
			;ask the user for the stock file.
			newFile := getMonoFile(defaultFile, strDetail)
			if (newFile == "")
			{
				msgbox, , RWDebugHelper, First time setup canceled.  Settings decisions made up to this point have been saved to %iniFile%.
				return
			}
			SplitPath, newFile, sFile, sDir
			sDir .= "\"
		}
	} else {
		;We didn't find the mono.dll file in the expected location but this isn't an error state either....
		;ask the user for the stock file.
		newFile := getMonoFile(defaultFile, strDetail)
		if (newFile == "")
			msgbox, , RWDebugHelper, First time setup canceled.  Settings decisions made up to this point have been saved to %iniFile%.
			return
		SplitPath, newFile, sFile, sDir
		sDir .= "\"
	}
	
	;if the selected file is the same as mono.dll then ask the user for a name to call the backup.
	if (sFile == monoFile)
	{
		InputBox, dFile, RWDebugHelper, Type in a new name for the stock file (for backup purposes):, , , , , , , , %defaultFile%
		if (ErrorLevel)
		{
			msgbox, , RWDebugHelper, First time setup canceled.  Settings decisions made up to this point have been saved to %iniFile%.
			return
		}
		doCopy := true
	}
	
	;if the file selected isn't in the same path as the Rimworld mono.dll file, flag it for copying.
	if (sDir != dDir)
		doCopy := true
	
	if (!dFile)
		dFile := sFile
	
	if (doCopy)
	{
		overwrite := 0
		if (FileExist(dDir . dFile))
		{
			MsgBox, 4, RWDebugHelper, % "Warning: While copying '" . sDir . sFile . "' to '" . dDir . dFile . "'.  File already exists in destination.  Would you like to overrite?"
			IfMsgBox, Yes
				overwrite := 1
		}
		FileCopy, % sDir . sFile, % dDir . dFile, %overwrite%
		if (ErrorLevel)
		{
			msgbox, 48, RWDebugHelper, % "Error code: " . A_LastError . " while copying '" . sDir . sFile . "' to '" . dDir . dFile . "'.  Setup is now ending."
			return
		}
	}
	return dFile
}

;determine if the value is a confirmation (Yes/No) string.
isConfirmation(val)
{
	StringLower, sl, val
	if (sl == "yes" or sl == "no")
		return true
	return false
}

;converts confirmation (yes/no) to bool (true/false)
confirmationToBool(val)
{
	StringLower, sl, val
	if (sl == "yes")
		return true
	if (sl == "no")
		return false
	throw "confirmation string not yes/no"
	return false
}

;converts bool (true/false) to confirmation (yes/no).  May not be used anymore.
boolToConfirmation(val)
{
	if (val)
		return "Yes"
	return "No"
}

;handles interacting with the user to find the path to Rimworld's mono.dll file.
;returns the path to the file and not the file.
getMonoPath(file)
{
	FileSelectFile, ret, % 1+2, %file%, Select Rimworld's %file% file., %file% (%file%)
	if (ret != "")
	{
		SplitPath, ret, , rDir
		ret := rDir
	}
	return ret
}

;handles getting the filename from the user (used by handleFileSelection)
getMonoFile(file, type)
{
	FileSelectFile, ret, % 1+2, %file%, Select the %type% file., %file%
	return ret
}


;coding utilities
#If A_IsCompiled = ""

; reload the script
!^t::
{
	Reload
	return
}

exitLabel:
{
	if (clipback != "")
		Clipboard := clipback
	
	if (rwPID != 0)
	{
		Process, Exist, %rwPID%
		if (ErrorLevel != 0)
			Process, Close, %rwPID%
	}
	
	if (debugFileActive)
		toggleDebugOff()
	
	ExitApp, 0
}

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
	
	rwPID := 0
	
	dirSrc := ".\RWRapidGameStart\"
	
	imageNewColony := dirSrc . "btnNewColony.bmp"
	imageNewColonyX := 84
	imageNewColonyY := 21
	
	imageNext := dirSrc . "btnNext.bmp"
	imageNextX := 74
	imageNextY := 18
	
	imageSelectDifficulty := dirSrc . "selectDifficulty.bmp"
	imageSelectDifficultyX := 278
	imageSelectDifficultyY := 12
	
	imageGenerate := dirSrc . "btnGenerate.bmp"
	imageNextX := 74
	imageNextY := 18
	
	imagePercent := dirSrc . "btnPercent.bmp"
	imagePercentX := 99
	imagePercentY := 14
	
	imageAdvanced := dirSrc . "btnAdvanced.bmp"
	imageAdvancedX := 74
	imageAdvancedY := 18
	
	imageSelectMapSize := dirSrc . "selectMapSize.bmp"
	imageSelectMapSizeX := 188
	imageSelectMapSizeY := 11
	
	imageClose := dirSrc . "btnClose.bmp"
	imageCloseX := 59
	imageCloxeY := 19
	
	imageSelectRandomSite := dirSrc . "btnSelectRandomSite.bmp"
	imageSelectRandomSiteX := 74
	imageSelectRandomSiteY := 18
	
	imageStart := dirSrc . "btnStart.bmp"
	imageStartX := 74
	imageStartY := 18
	
	imageMenu := dirSrc . "menuMenu.bmp"
	imageMenuX := 22
	imageMenuY := 9
	
	imageQuitToBase := dirSrc . "btnQuitToBase.bmp"
	imageQuitToBaseX := 84
	imageQuitToBaseY := 21
	
	imageConfirm := dirSrc . "btnConfirm.bmp"
	imageConfirmX := 140
	imageConfirmY := 16
	
	return
}

F12::
{
	rimWorldRunning()
	return
}

#IfWinActive, RimWorld by Ludeon Studios

F12::
{
	gosub doMainGameStart
	return
}

rimWorldRunning()
{
	global rwPID
	if (rwPID != 0)
	{
		Process, Exist, %rwPID%
		if (ErrorLevel = 0)
			rwPID := 0
	}
	if (rwPID = 0)
		rwPID := WinExist("ahk_exe RimWorld1546Win.exe")
	if (rwPID = 0)
		Run, D:\Games\RimWorld1546Win\RimWorld1546Win.exe, D:\Games\RimWorld1546Win\, rwPID
	if (rwPID != 0)
		return true
	return false
}

F11::
{
	;click the menu button to quit...
	MouseMove, 0, 50
	ImageSearch, x, y, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imageMenu%
	if (ErrorLevel)
		return
	x += imageMenuX
	y += imageMenuY
	MouseClick, Left, %x%, %y%
	
	;Wait for the menu to appear.
	MouseMove, 0, 50
	er := 1
	while (er)
	{
		ImageSearch, x, y, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imageQuitToBase%
		er := ErrorLevel
	}
	x += imageQuitToBaseX
	y += imageQuitToBaseY
	MouseClick, Left, %x%, %y%
	
	;Wait for the confirmation to appear.
	MouseMove, 0, 50
	er := 1
	while (er)
	{
		ImageSearch, x, y, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imageConfirm%
		er := ErrorLevel
	}
	x += imageConfirmX
	y += imageConfirmY
	MouseClick, Left, %x%, %y%
	
	;Wait for the main screen to appear and branch to the other path of code.
	MouseMove, 0, 50
	er := 1
	while (er)
	{
		ImageSearch, x, y, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imageNewColony%
		er := ErrorLevel
	}
	gosub doMainGameStart
	
	return
}

F10::
{
	;Wait for the main screen to appear and branch to the other path of code.
	MouseMove, 0, 50
	er := 1
	while (er)
	{
		ImageSearch, x, y, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imageNewColony%
		er := ErrorLevel
	}
	gosub doMainGameStart
	
	return
}

doMainGameStart:
{
	;select New Colony button or error out if not present.
	MouseMove, 0, 50
	ImageSearch, x, y, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imageNewColony%
	if (ErrorLevel)
		return
	x += imageNewColonyX
	y += imageNewColonyY
	MouseClick, Left, %x%, %y%
	
	;wait for Next button to appear (Choose Scenario screen)
	MouseMove, 0, 50
	er := 1
	while (er)
	{
		ImageSearch, x, y, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imageNext%
		er := ErrorLevel
	}
	x += imageNextX
	y += imageNextY
	MouseClick, Left, %x%, %y%
	
	;wait for difficulty selection to appear (AI Storyteller/Difficulty), select difficulty then click next.
	MouseMove, 0, 50
	er := 1
	while (er)
	{
		ImageSearch, x, y, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imageSelectDifficulty%
		er := ErrorLevel
	}
	x += imageSelectDifficultyX
	y += imageSelectDifficultyY
	MouseClick, Left, %x%, %y%
	
	ImageSearch, x, y, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imageNext%
	x += imageNextX
	y += imageNextY
	MouseClick, Left, %x%, %y%
	
	;wait for Generate button to appear (Create world)
	MouseMove, 0, 50
	er := 1
	while (er)
	{
		ImageSearch, gx, gy, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imageGenerate%
		er := ErrorLevel
	}
	gx += imageGenerateX
	gy += imageGenerateY
	
	;click the percent button and choose smallest (estimated) then click generate.
	ImageSearch, x, y, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imagePercent%
	x += imagePercentX
	y += imagePercentY
	MouseClick, Left, %x%, %y%
	
	Sleep, 100
	x += 50
	y += 20
	MouseClick, Left, %x%, %y%
	
	Sleep, 100
	
	MouseClick, Left, %gx%, %gy%
	
	;Wait for Next button to appear (Select Landing Site)
	MouseMove, 0, 50
	er := 1
	while (er)
	{
		ImageSearch, nx, ny, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imageNext%
		er := ErrorLevel
	}
	nx += imageNextX
	ny += imageNextY
	
	;Click Advanced, select desired map size, click close, click select random, then click next.
	ImageSearch, x, y, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imageAdvanced%
	x += imageAdvancedX
	y += imageAdvancedY
	MouseClick, Left, %x%, %y%
	
	MouseMove, 0, 50
	er := 1
	while (er)
	{
		ImageSearch, cx, cy, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imageClose%
		er := ErrorLevel
	}
	cx += imageCloseX
	cy += imageCloseY
	
	ImageSearch, x, y, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imageSelectMapSize%
	x += imageSelectMapSizeX
	y += imageSelectMapSizeY
	MouseClick, Left, %x%, %y%
	
	MouseClick, Left, %cx%, %cy%
	
	Sleep, 100
	
	ImageSearch, x, y, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imageSelectRandomSite%
	x += imageSelectRandomSiteX
	y += imageSelectRandomSiteY
	MouseClick, Left, %x%, %y%
	
	Sleep, 100
	
	MouseClick, Left, %nx%, %ny%
	
	MouseMove, 0, 50
	;Wait for the Start button (Create Characters/Start)
	MouseMove, 0, 50
	er := 1
	while (er)
	{
		ImageSearch, x, y, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, %imageStart%
		er := ErrorLevel
	}
	x += imageStartX
	y += imageStartY
	MouseClick, Left, %x%, %y%
	
	return
}

;coding utilities
#If A_IsCompiled = ""

; reload the script
!^r::
{
	Reload
	return
}


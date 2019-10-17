;-------------------------------------------------------------------------------
; PROJECT NAME: NodePop! Beta ;)
; DESCRIPTION: a node spawner for Notch with experimental HTML GUI.
;		This version is not finished as some features are not working.
;		I just wanted to try making a nicer GUI in HTML. And this is what I created.
; COMPATIBLE WITH NOTCH VERSION: 0.9.22.065

; USAGE: Hit Ctrl+Space while Notch-ing, write the name of a node in popup window (or use an abbreviation), hit Enter and Pop!
;		 Right click on tray icon and go to settings - you can set there hotkeys for specific node's spawning.
;
; crafted by Martin Winged @ Piloci Studio
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; ROADMAP
;
;	- on double click on result - spawn that node
;	- create HTML GUI for settings
;	- FixIE(): check if registry key has already a proper value to avoid changing it
;	- slider for adapting script speed
;	- remove "WM_KEYDOWN" when not needed at the very end
;	* 
;	* add bolding of text to results based on inputed text
;	* ability to bind as many hotkeys as needed for any node popping
;	* add animations in CSS for showing, hiding and scrolling results
;	* add a hidden button in right upper corder of popup tool GUI to switch to a 'next page'
;	* split HTML code to a different file
;	* implement classes
;
; end of ROADMAP
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; SET UP DIRECTIVES

#Persistent ; This keeps the script running permanently.
#SingleInstance Force ; Only allows one instance of the script to run.
#WinActivateForce
SetTitleMatchMode, 2 ; A window's title can contain WinTitle anywhere inside it to be a match
CoordMode, Mouse, Screen ; Check on what screen mouse is right now - needed for testing window focus
SetBatchLines, -1
SetWinDelay, 0
OnExit,OnExit

; end of SET UP DIRECTIVES
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; SET UP MAIN GLOBAL VARIABLES

; Array of most commonly used nodes
; CommonNodes[index]: reference to Nodes[] element
CommonNodes := []

; Array of favourite nodes spawnable by keyboard shortcuts
; FavouriteNodes[index]: {
;	nodeID: "none" OR <1, Nodes.MaxIndex()
;	"shortcut": "none" OR f.e. "^1"
;	db: "none" OR XML reference
; }
FavouriteNodes := []

; Array of all nodes
; Nodes[index]: {
;	nodeName: f.e. "Cylindrical Camera"
;	mainCategory: f.e. "Particles"
;	subCategory: f.e. "Emitter"
;	colour: f.e. ff5f53
;	phrasesArray: f.e. ["Cylindircal" "Camera" "(Cameras)"]
;	position: /integer/ <1, +>
;	frequency: /integer/ <0, +>
;	nodeID: <1, Nodes.MaxIndex()
;	db: XML reference
; }
Nodes := []

; Any extra options
ExtrasOption := {}

; Count number of nodes spawned
SpawnCounter := 0

; Variable to store active Notch window PID
NotchWindowPID := ""
ToolWindowPID := ""

; GUI control variables
SelectedIndex = 1
ScrollOffset = 0

; end of SET UP MAIN GLOBAL VARIABLES
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; FORCE NEWER IE RENDERER

FixIE(Version=0, ExeName="") {
	static Key := "Software\Microsoft\Internet Explorer"
	. "\MAIN\FeatureControl\FEATURE_BROWSER_EMULATION"
	, Versions := {7:7000, 8:8888, 9:9999, 10:10001, 11:11001}
	
	if Versions.HasKey(Version)
		Version := Versions[Version]
	
	if !ExeName
	{
		if A_IsCompiled
			ExeName := A_ScriptName
		else
			SplitPath, A_AhkPath, ExeName
	}
	
	RegRead, PreviousValue, HKCU, %Key%, %ExeName%
	if (Version="")
		RegDelete, HKCU, %Key%, %ExeName%
	else
		RegWrite, REG_DWORD, HKCU, %Key%, %ExeName%, %Version%
	return PreviousValue
}

FixIE()

; end of FORCE NEWER IE RENDERER
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; SET UP HTML PAGES CODE

	;-------------------------------------------------------------------------------
	; GUI THEME COLOURS

	ThemeElement = 333
	ThemeLineGray = 8e9190
	ThemeColour1 = 7ba984
	ThemeColour2 = aa3377
	ThemeColour3 = ff6c46
	ThemeGray1 = 3c3c3c
	ThemeGray2 = 282828
	ThemeSelected = 717171
	TransparencyColour = 3a3a3a

	; end of GUI THEME COLOURS
	;-------------------------------------------------------------------------------


NP_ToolWindow_HTML_String =
( Ltrim Join
<!DOCTYPE html>
<html>

<head>
	<style>
		* {
			box-sizing: border-box;
			margin: 0;
			padding: 0;
			border: 0;
		}

		body {
			transform: scale(0.8);
			transform-origin: top left;
			background-color: #%TransparencyColour%;
		}

		.container {
			width: 742px;
		}

		.search_bar {
			height: 66px;
			width: 100`%;
			position: relative;
		}

		@keyframes animated_colour1 {
			0`%   { background-color: #%ThemeColour1%; }
			33`%  { background-color: #%ThemeColour2%; }
			66`%  { background-color: #%ThemeColour3%; }
			100`% { background-color: #%ThemeColour1%; }
		}

		@keyframes animated_colour2 {
			0`%   { background-color: #%ThemeColour3%; }
			33`%  { background-color: #%ThemeColour1%; }
			66`%  { background-color: #%ThemeColour2%; }
			100`% { background-color: #%ThemeColour3%; }
		}

		@keyframes animated_colour3 {
			0`%   { background-color: #%ThemeColour2%; }
			33`%  { background-color: #%ThemeColour3%; }
			66`%  { background-color: #%ThemeColour1%; }
			100`% { background-color: #%ThemeColour2%; }
		}

		.search_bar * {
			margin: 0px;
			position: absolute;
			height: 66px;
			width: 100`%;
		}

		.search_icon {
			margin-left: 10px;
			position: absolute;
			width: 66px;
			height: 66px;
			transform: scale(0.7);
		}

		.search_circle {
			position: absolute;
			width: 75`%;
			height: 75`%;
			border: 10px solid #%ThemeElement%;
			border-radius: 100px;
		}

		.search_rectangle {
			position: absolute;
			right: 0;
			top: 45px;
			height: 10px;
			width: 30px;
			transform: rotate(45deg);
			background-color: #%ThemeElement%;
			border-top-right-radius: 12px;
			border-bottom-right-radius: 12px;
		}

		#InputText {
			border: none;
			margin-left: 80px;
			width: 630px;
			background: none;
			color: #FFFFFF;
			font-size: 30px;
			font-family: "Lato", Times, serif;
		}

		.solid-line {
			width: 100`%;
			height: 3px;
			background-color: #%ThemeLineGray%;
		}

		@keyframes animated_gradient {
			0`%   { background-position: 200`% 50`%; }
			100`% { background-position: 0`% 50`%; }
		}

		.animated-line {
			width: 100`%;
			height: 3px;
			background: linear-gradient(270deg, #%ThemeColour1%, #%ThemeColour2%, #%ThemeColour3%, #%ThemeColour1%);
			background-size: 200`%;
			animation-name: animated_gradient;
			animation-duration: 4s;
			animation-timing-function: linear;
			animation-iteration-count: infinite;
		}

		#DisplayedResults {
			display: flex;
			flex-direction: column;
			font-size: 20px;
			font-family: "Lato", Times, serif;
			font-weight: lighter;
			color: white;
		}

		.result {
			display: flex;
			flex-direction: row;
			background-color: #%ThemeGray1%;
			width: 100`%;
			padding-left: 6`%;
		}

		.selected {
			background-color: #%ThemeSelected%;
		}

		.triangle {
			margin: 7px 0px 7px 0px;
			width: 0;
			height: 0;
			margin-right: 15px;
			border-style: solid;
			border-width: 12px 0 12px 20.8px;
			border-color: transparent transparent transparent #aa3377;
		}

		.nodeName {
			padding: 7px 0px 7px 0px;
			position: absolute;
		}

		.node_category {
			padding: 7px 0px 7px 0px;
			position: absolute;
			padding-left: 5`%;
		}

		.mainCategory {
			font-family: "Lato", Times, serif;
			font-weight: bold;
		}

		.result_separator {
			width: 1px;
			margin-left: 50`%;
			background-color: white;
		}

		.result.even {
			background: linear-gradient(90deg, transparent 3`%, #%ThemeGray2% 3`%, #%ThemeGray2% 100`%);
		}

		.result.even.selected {
			background: linear-gradient(90deg, transparent 3`%, #%ThemeSelected% 3`%, #%ThemeSelected% 100`%);
		}

		.result:last-of-type {
			position: relative;
		}
	</style>
</head>

<body>
	<div class="container">
		<div class="search_bar">

			<div style="animation-name: animated_colour1; animation-duration: 4s; animation-iteration-count: infinite; border-radius: 10px 20px 0px 0px; z-index: 1"></div>
			<div style="animation-name: animated_colour2; animation-duration: 4s; animation-iteration-count: infinite; border-radius: 10px 35px 0px 0px; z-index: 2"></div>
			<div style="animation-name: animated_colour3; animation-duration: 4s; animation-iteration-count: infinite; border-radius: 10px 50px 0px 0px; z-index: 3"></div>
			<div style="background-color: #%ThemeGray2%; border-radius: 5px 66px 0px 0px; z-index: 4"></div>

			<div class="search_icon" style="z-index: 5">
				<div class="search_circle"></div>
				<div class="search_rectangle"></div>
			</div>

			<input type="text" id="InputText" style="z-index: 6"></input>

		</div>

		<div>
			<div class="solid-line"></div>
			<div class="animated-line"></div>
		</div>

		<div id="DisplayedResults"></div>


	</div>
</body>

</html>
)

; Create temporary file with html and link it to variable
ToolWindow_HTML_File := PrepareHTML( NP_ToolWindow_HTML_String )

; end of SET UP HTML PAGES CODE
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; PREPARE TOOL WINDOW GUI

; Specify max dimensions of tool window
NP_ToolWindow_Width = 742
NP_ToolWindow_Height = 480

; Specify tool window name
ToolWindow_Title = "NodePop! ToolWindow"

; Set transparency background colour - the same as typed in CSS
Gui NP_ToolWindow:+LastFound +AlwaysOnTop -Caption +ToolWindow
WinSet, TransColor, %TransparencyColour%

; Add ActiveX component to GUI
Gui NP_ToolWindow:Add, ActiveX, x0 y0 w%NP_ToolWindow_Width% h%NP_ToolWindow_Height% vWB, Shell.Explorer

; Surpress JavaScript error boxes
WB.silent := true

; Display HTML code
DisplayHTML( ToolWindow_HTML_File )

; Wait for IE to load the page, before we connect the event handlers
while WB.readystate != 4 or WB.busy
	sleep 100

; Connect text input element
InputTextElement := WB.document.getElementById("InputText")
ComObjConnect(InputTextElement, "InputText_")

; Connect results div element
DisplayedResultsElement := WB.document.getElementById("DisplayedResults")
ComObjConnect(DisplayedResultsElement, "DisplayedResults_")


; end of PREPARE GUI TOOL WINDOW
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; SET UP EVENT ACCELERATORS
; https://autohotkey.com/board/topic/87477-send-enter-key-to-activex-ie-control/
;
; Enables on key UP/DOWN event listener

WM_KEYDOWN = 0x100
WM_KEYUP = 0x101
OnMessage(WM_KEYDOWN, "WM_KEYDOWN")
OnMessage(WM_KEYUP, "WM_KEYUP")

WM_KEYDOWN(wParam, lParam, nMsg, hWnd) {
	global WB
	static fields := "hWnd,nMsg,wParam,lParam,A_EventInfo,A_GuiX,A_GuiY"

	WinGetClass, ClassName, ahk_id %hWnd%

	; http://www.autohotkey.com/community/viewtopic.php?p=562260#p562260
	if (ClassName = "Internet Explorer_Server") {	
		pipa := ComObjQuery(WB, "{00000117-0000-0000-C000-000000000046}")
		VarSetCapacity(kMsg, 48)

		Loop Parse, fields, `,
			NumPut(%A_LoopField%, kMsg, (A_Index-1)*A_PtrSize)

		Loop 2 ; only necessary for Shell.Explorer Object
			r := DllCall(NumGet(NumGet(1*pipa)+5*A_PtrSize), "ptr",pipa, "ptr",&kMsg)
		until wParam != 9 || WB.document.activeElement != ""

		ObjRelease(pipa)

		; S_OK: the message was translated to an accelerator.
		if r = 0
			return 0
	}
}

WM_KEYUP(wParam, lParam, nMsg, hWnd) {
	global WB
	static fields := "hWnd,nMsg,wParam,lParam,A_EventInfo,A_GuiX,A_GuiY"

	WinGetClass, ClassName, ahk_id %hWnd%

	; http://www.autohotkey.com/community/viewtopic.php?p=562260#p562260
	if (ClassName = "Internet Explorer_Server") {	
		pipa := ComObjQuery(WB, "{00000117-0000-0000-C000-000000000046}")
		VarSetCapacity(kMsg, 48)

		Loop Parse, fields, `,
			NumPut(%A_LoopField%, kMsg, (A_Index-1)*A_PtrSize)

		Loop 2 ; only necessary for Shell.Explorer Object
			r := DllCall(NumGet(NumGet(1*pipa)+5*A_PtrSize), "ptr",pipa, "ptr",&kMsg)
		until wParam != 9 || WB.document.activeElement != ""

		ObjRelease(pipa)

		; S_OK: the message was translated to an accelerator.
		if r = 0
			return 0
	}
}

WB.document.addEventListener("keyup", Func("TextInputHandler"))

; end of SET UP EVENT ACCELERATORS
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; SET UP DATABASE

DBPath = %A_ScriptDir%\include\database.xml

; Import XML management library
#Include %A_ScriptDir%\include\xml.ahk

; Load XML file database
FileRead, XMLFile, %DBPath%

try ; Create an XMLDOMDocument object and load the XML string
	DOM := new xml(XMLFile)
catch pe ; Catch parsing error (if any)
	MsgBox, 16, PARSE ERROR
	, % "Exception thrown!!`n`nWhat: " pe.What "`nFile: " pe.File
	. "`nLine: " pe.Line "`nMessage: " pe.Message "`nExtra: " pe.Extra

; Load favourite nodes
InitializeDatabase()

; DEBUG ONLY
ResetDatabase()

; end of SET UP DATABASE
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; LOAD IMAGES

; Load large icon image for settings menu
nodepop_image = %A_ScriptDir%\include\nodepop.png

; Load icon image
nodepop_ico = %A_ScriptDir%\include\nodepop.ico

; end of LOAD IMAGES
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; SET UP TRAY MENU

; Turn off default AHK tray options
Menu, Tray, NoStandard
;Menu, Tray, Icon, %A_ScriptDir%\nodepop.ico
Menu, Tray, Icon, %nodepop_ico%

; Create main tray menu
Menu, Tray, Add, Settings, ShowSettingsWindow
Menu, Tray, Add, Exit, MenuExit

; Exit application from tray menu
MenuExit()
{
	ExitApp
}

; end of SET UP TRAY MENU
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
	Return
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; HOTKEYS HANDLING

; Conjure NodePop tool window
$^Space::GoSub, ShowToolWindow

; Hide GUI
$Esc::GoSub, HideToolWindow

; Allow Ctrl+A to select all inputed text
$^a:: GoSub, PressedCtrlA

; Handle arrrow down keypress
$Down:: GoSub, PressedArrowDown

; Handle arrrow down keypress
$Up:: GoSub, PressedArrowUp

; Handle Enter keypress
$Enter:: GoSub, PressedEnter

; end of HOTKEYS HANDLING
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; ON EXIT MANAGEMENT
OnExit:
	; Clean TMP file
	FileDelete,%A_Temp%\*.DELETEME.html
ExitApp

; end of ON EXIT MANAGEMENT
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; HOTKEYS SUBROUTINES

PressedCtrlA:
	; Continue only if tool window is active
	IfWinActive %ToolWindow_Title%
	{
		InputTextElement.select()
	} else {
		; If is not active, just pass through key combination
		Send, ^a
	}
Return

; Set behaviour of Arrow Down for result selection
PressedArrowDown:
	; Continue only if tool window is active
	IfWinActive %ToolWindow_Title%
	{
		if (SelectedIndex > SearchResults.MaxIndex() - 1)
			Return

		SelectedIndex += 1

		if (SelectedIndex > 5 + ScrollOffset) {
			ScrollOffset += 1
		}

		RefreshDisplayedResult()
	} else {
		; If is not active, just pass through key combination
		Send, {Down}
	}
Return

; Set behaviour of Arrow Up for result selection
PressedArrowUp:
	; Continue only if tool window is active
	IfWinActive %ToolWindow_Title%
	{
		if (SelectedIndex = 1)
			Return

		SelectedIndex -= 1
		
		if (SelectedIndex < ScrollOffset + 1) {
			ScrollOffset -= 1
		}

		RefreshDisplayedResult()
	} else {
		; If is not active, just pass through key combination
		Send, {Up}
	}
Return

PressedEnter:
	; Continue only if tool window is active
	IfWinActive %ToolWindow_Title%
	{
		ChosenResult := SearchResults[SelectedIndex]

		GoSub, HideToolWindow

		SpawnNode(ChosenResult)
	} else {
		; If is not active, just pass through key combination
		Send, {Enter}
	}
Return

; end of HOTKEYS SUBROUTINES
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; PROCESS INPUTED TEXT INTO TOOLWINDOW

; On typed text change
TextInputHandler() {
	global WB
	global Nodes
	global SearchResults
	global ExtrasOption
	global ScrollOffset
	global SelectedIndex
	global CommonNodes

	; On letter typed - reset scrolling value and select top result
	ScrollOffset = 0
	SelectedIndex = 1

	TypedText := WB.document.getElementById("InputText").value

	; TODO: Script does not count last typed char (onkeyup does not work)

	; If there is no text typed
	If StrLen(TypedText) < 1
	{
		; Show most frequently used nodes
		SearchResults := CommonNodes

		; Update displayed result list
		RefreshDisplayedResult()

		Return
	}

	; Prepare array for text matches
	SearchResults := []

	; Split input string into words and check all words against Nodes names
	WordArray := StrSplit(TypedText, A_Space, ".")

	; Pass all node names through String Similarity algorithm
	if (ExtrasOption["Spelling Correction"].value = 1) {
		; Iterate through all node names array
		for index, element in Nodes
		{
			SearchResults.Push(element)
		}

		SearchResults := SortResults(TypedText)
	}
	; Show and sort only results that matches typed text; sorting based on frequency usage
	else {
		FrequencyArrayHelper := []
		; Iterate through all node names array
		for index, element in Nodes
		{
			; Make a temp name array variable to freely work on it later
			TempNodeName := element.phrasesArray.Clone()
			; Match find flag
			isMatching := 1

			; Iterate through all typed phrases
			for phrase_index, phrase in WordArray
			{
				; If did not found a match for a phrase inside a node name
				If GetInStrArrayIndex(TempNodeName, phrase) < 0
				{
					; Mark this node name as not matching and stop comparing next phrases
					isMatching = 0
					break
				}
				Else
				{
					; If found a match word, remove it from next loop
					TempNodeName.Remove(GetInStrArrayIndex(TempNodeName, phrase))
				}
			}

			; If all phrases are found inside node name
			if isMatching = 1
			{
				; Push this node name into an array
				SearchResults.Push(element)
				FrequencyArrayHelper.Push(element.frequency)
			}
		}

		; Sort output array based on frequency node spawning
		SearchResults := UndercoverArraySort(SearchResults, FrequencyArrayHelper)
	}

	; Update displayed result list
	RefreshDisplayedResult()
}

; Read results array and use it to update HTML results div
RefreshDisplayedResult() {
	global WB
	global SearchResults
	global SelectedIndex
	global ScrollOffset

	; Prepare clean text variable
	result_text =

	; Loop through results array
	for index, element in SearchResults
	{
		if (index < ScrollOffset + 1)
			continue

		if (index > ScrollOffset + 5)
			break

		if ( Mod(index, 2) = 0 ) {
			isEven = even
		} else {
			isEven =
		}

		nodeName := element.nodeName
		mainCategory := element.mainCategory
		subCategory := element.subCategory
		colour := element.colour
		isSelected =

		; Add 'selected' class to selected index
		if (index = SelectedIndex) {
			isSelected = selected
		}

		; Append HTML string of one row of result
		result_text = %result_text%
		(
			<div class="result %isSelected% %isEven%">
				<span class="triangle" style="border-color: transparent transparent transparent #%colour%"></span>
				<p class="nodeName">%nodeName%</p>
				<span class="result_separator"></span>
				<p class="node_category"><span class="mainCategory">%mainCategory%</span> > <span>%subCategory%</span></p>
			</div>
		)
	}

	; Replace HTML text of 'DisplayedResults' div
	WB.document.getElementById("DisplayedResults").innerHTML := result_text
}

; end of PROCESS INPUTED TEXT INTO TOOLWINDOW
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; NODEPOP TOOL WINDOW MANAGEMENT

ShowToolWindow:
	; Check if Notch window is active
	Winget, AppName, ProcessName, A
	If ( AppName != "NotchApp.exe" ) {
		Send, ^{Space}
		Return
	}

	; Store PID of active Notch window
	WinGet, NotchWindowPID, PID, A

	; If this window is visible, hide it before showing it again
	IfWinActive, % ToolWindow_Title
		GoSub, HideToolWindow

	; Reset result selection
	ScrollOffset = 0
	SelectedIndex = 1

	; Show the window
	; Spawn it way outside and move it later to screen to hide ActiveX transparency blinking
	Gui NP_ToolWindow:Show, w%NP_ToolWindow_Width% h%NP_ToolWindow_Height% x100000 y100000, %ToolWindow_Title%
	Sleep 50

	; Move tool window to mouse position
	MouseGetPos, MouseX, MouseY
	WinMove, %ToolWindow_Title%,,MouseX, MouseY

	; Update list of most frequently used nodes
	RefreshCommonNodes()

	; Show most frequently used nodes
	SearchResults := CommonNodes

	; Update displayed result list
	RefreshDisplayedResult()

	; Focus on input field immediately
	WB.document.getElementById("InputText").Focus()
Return

HideToolWindow:
	Gui NP_ToolWindow:Hide

	WB.document.getElementById("InputText").value := ""
	WB.document.getElementById("DisplayedResults").innerHTML := ""
Return

; end of NODEPOP TOOL WINDOW MANAGEMENT
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; NODEPOP SETTINGS WINDOW MANAGEMENT

ShowSettingsWindow:

Return

HideSettingsWindow:

Return

; end of NODEPOP SETTINGS WINDOW MANAGEMENT
;-------------------------------------------------------------------------------



; Do some keystrokes in order to spawn provided node name onto nodegraph
; Use clipbaord to paste quickly node name instead of slowly typing it
SpawnNode(NodeIn) {
	global NotchWindowPID
	global SpawnCounter

	; Focus on Notch window
	WinActivate ahk_pid %NotchWindowPID%

	; Wait for Notch window to become active
	WinWaitActive ahk_pid %NotchWindowPID%

	name := NodeIn.nodeName
	; Remove brackets string part f.e. "(Cameras)"
	ProperNodeName := SubStr(name, 1 , InStr(name, "(") - 2)

	; Save the entire clipboard to temporal variable
	ClipSaved := ClipboardAll
	; Empty the clipboard (start off empty to allow ClipWait to detect when the text has arrived)
	clipboard := ""
	; Paste node name to clipboard
	clipboard = %ProperNodeName%
	ClipWait

	; Focus on Nodes editbox and clear it
	Send, ^e
	Send, ^e
	Send, ^e
	; Paste selected node name from clipboard
	Send, ^v

	; Send down arrow key to reach proper node entry
	Loop % NodeIn.position
	{
		Send, {Down}
		Sleep, 40
	}

	; Place node in nodegraph
	Sleep, 10
	Send, {Enter}

	; Restore original clipboard
	clipboard := ClipSaved
	; Free the memory in case the clipboard was very large
	ClipSaved =

	; Clear it node-name-box
	Send, ^e
	Send, ^e

	; Refresh mouse position (otherwise it's invisible)
	MouseMove, 1, 1, 1, R

	; Update usgae frequency of the node
	NodeIn.frequency += 1
	NodeIn.db.setAttribute("frequency", NodeIn.frequency)

	SpawnCounter += 1

	; Save database every 10 spawned nodes
	If ( Mod(SpawnCounter, 10) = 0 ) {
		SaveDatabase()
	}
}



;-------------------------------------------------------------------------------
; HOTKEYS MANAGEMENT

; Turn hotkey on or off
UpdateHotkey(hotkey_number, hotkey_shortcut, state = "On") {
	Hotkey, % hotkey_shortcut, % "FavHotkey" hotkey_number, % state
}

; end of HOTKEYS MANAGEMENT
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; HTML CODE MANAGEMENT

; Prepare temporary file and fill it with HTML string
PrepareHTML( html_str ) {
	Count := 0
	while % FileExist( file := A_Temp "\" A_TickCount A_NowUTC "-tmp" Count ".DELETEME.html" )
		Count += 1

	FileAppend, %html_str%, %file%

	return file
}

; Open temporary HTML file with web browser
DisplayHTML( file ) {
	global WB

	WB.Navigate( "file://" . file )
}

; end of HTML CODE MANAGEMENT
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; SEARCH RESULTS MANAGEMENT

; Refresh list of the most common nodes
RefreshCommonNodes() {
	global Nodes
	global CommonNodes

	; Clean array
	CommonNodes := []

	; Iterate through every node info and compare it's usage frequency
	for index, element in Nodes
	{
		; Populate array with any nodes to compare with them later
		If (CommonNodes.MaxIndex() < 5) {
			CommonNodes.Push(Nodes[A_Index])
			continue
		}

		; Choose 5 most common nodes
		Loop, 5
		{
			If element.frequency > CommonNodes[A_Index].frequency
			{
				; If found a more frequent node, insert it above this node
				CommonNodes.InsertAt(A_Index, element)
				; Keep array's right dimension
				CommonNodes.Remove(6)
				break
			}
		}
	}
}

SortResults(TypedText) {
	global SearchResults

	SimilarityArray := []

	for index, element in SearchResults
	{
		SimilarityArray.Push(StringCompare(TypedText, element.nodeName))
	}

	Return UndercoverArraySort(SearchResults, SimilarityArray)
}

; end of SEARCH RESULTS MANAGEMENT
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; DATABASE MANAGEMENT

; Process XML database and output it to a readable array
LoadNodesEntries() {
	global DOM

	OutputArray := []

	if DOM.documentElement {
		; Get all categories
		RootChildren := DOM.getChildren("root", "element")

		; Iterate through main categories
		Loop % RootChildren.MaxIndex() {
			Category := RootChildren[A_Index]
			CategoryStr := Category.getAttribute("name")

			; If found "Favourites Nodes" category
			If ( CategoryStr = "Favourite Nodes" || CategoryStr = "Extras" ) {
				; Skip it
				continue	
			}

			; Get cattegory colour
			ColourVal := Category.getAttribute("colour")

			; Get all sub categories
			CategoryChildren := DOM.getChildren(Category, "element")
			; Iterate through sub categories
			Loop % CategoryChildren.MaxIndex() {
				Subcategory := CategoryChildren[A_Index]
				SubcategoryStr := Subcategory.getAttribute("name")

				; Get all subcategory children nodes
				SubcategoryChildren := DOM.getChildren(Subcategory, "element")
				; Iterate through all subcategory children nodes
				Loop % SubcategoryChildren.MaxIndex() {
					Node := SubcategoryChildren[A_Index]

					; Read node attributes
					NodeNameStr := Node.getAttribute("name")
					NodePositionVal := Node.getAttribute("position")
					NodeFrequencyVal := Node.getAttribute("frequency")
					NodeID := Node.getAttribute("ID")

					; Push complete node info to main Nodes array
					newElem := {}
					newElem.nodeName := NodeNameStr
					newElem.mainCategory := CategoryStr
					newElem.subCategory := SubcategoryStr
					newElem.colour := ColourVal
					newElem.position := NodePositionVal
					newElem.frequency := NodeFrequencyVal
					newElem.db := Node
					newElem.nodeID := NodeID

					; Prepare array of phrases that will be later used for matching with typed text
					newElem.phrasesArray := StrSplit(NodeNameStr, A_Space)
					newElem.phrasesArray.Push(CategoryStr)
					If not (SubcategoryStr == "Root") {
						newElem.phrasesArray.Push(SubcategoryStr)
					}

					OutputArray.Push(newElem)
				}
			}
		}
	}

	Return OutputArray
}

LoadFavouriteNodesEntries() {
	global DOM

	OutputArray := []

	if DOM.documentElement {
		; Get all categories
		RootChildren := DOM.getChildren("root", "element")

		; Iterate through main categories
		Loop % RootChildren.MaxIndex() {
			Category := RootChildren[A_Index]

			; If found "Favourite Nodes" category
			If ( Category.getAttribute("name") = "Favourite Nodes" ) {
				CategoryChildren := DOM.getChildren(Category, "element")

				; Loop through all favourite nodes entries
				Loop % CategoryChildren.MaxIndex() {
					Slot := CategoryChildren[A_Index]

					; Read slot attributes
					NodeID := Slot.getAttribute("nodeID")
					SlotShortcut := Slot.getAttribute("shortcut")

					; Prepare output array element applyring it's defaults
					OutputArray[A_Index] := { nodeID: "none", shortcut: "none", db: "none"}

					; If slot is assigned
					If ( ( NodeID != "none" ) && ( SlotShortcut != "none" ) ) {
						; Put this info into OutputArray
						OutputArray[A_Index].nodeID := NodeID
						OutputArray[A_Index].shortcut := SlotShortcut

						; Turn on hotkey for this favourite
						UpdateHotkey(A_Index, SlotShortcut, "On")
					}

					; Assign database slot
					OutputArray[A_Index].db := Slot
				}
			}
		}
	}

	Return OutputArray	
}

LoadExtrasEntries() {
	global DOM

	OutputObject := {}

	if DOM.documentElement {
		; Get all categories
		RootChildren := DOM.getChildren("root", "element")

		; Iterate through main categories
		Loop % RootChildren.MaxIndex() {
			Category := RootChildren[A_Index]

			; If found "Extras" category
			If ( Category.getAttribute("name") = "Extras" ) {
				CategoryChildren := DOM.getChildren(Category, "element")

				; Loop through all extras option entries
				Loop % CategoryChildren.MaxIndex() {
					Option := CategoryChildren[A_Index]

					; Read slot attributes
					OptionName := Option.getAttribute("name")
					OptionValue := Option.getAttribute("value")

					OutputObject.Insert(OptionName, {value:OptionValue, db: Option})
				}
			}
		}
	}

	Return OutputObject		
}

; Resets database to default
ResetDatabase() {
	global Nodes
	global FavouriteNodes
	global ExtrasOption

	; Reset frequency entries
	for index, element in Nodes
	{
		element.db.setAttribute("frequency", 0)
	}

	; Reset "Favourite Nodes" category
	for index, element in FavouriteNodes
	{
		element.db.setAttribute("nodeID", "none")
		element.db.setAttribute("shortcut", "none")
	}

	for index, element in ExtrasOption
	{
		element.db.setAttribute("value", 0)
	}

	; Save database to file
	SaveDatabase()

	; Load again values for global runtime arrays
	InitializeDatabase()
}

; Updates database entires applying data from runtime arrays
UpdateDatabase(WhatToUpdate = "all") {
	global Nodes
	global FavouriteNodes
	global ExtrasOption

	If (WhatToUpdate = "frequency" || WhatToUpdate = "all") {
		; Update frequency entries
		for index, element in Nodes
		{
			element.db.setAttribute("frequency", element.frequency)
		}
	}

	If (WhatToUpdate = "favourites" || WhatToUpdate = "all") {
		; Update "Favourite Nodes" category
		for index, element in FavouriteNodes
		{
			element.db.setAttribute("nodeID", element.nodeID)
			element.db.setAttribute("shortcut", element.shortcut)
		}		
	}

	If (WhatToUpdate = "extras" || WhatToUpdate = "all") {
		; Update "Extras" category
		for key, option in ExtrasOption
		{
			option.db.setAttribute("value", option.value)
		}		
	}
}

; After loading database, fill up all runtime values/arrays
InitializeDatabase() {
	global Nodes
	global FavouriteNodes
	global ExtrasOption

	Nodes := LoadNodesEntries()
	FavouriteNodes := LoadFavouriteNodesEntries()
	ExtrasOption := LoadExtrasEntries()
}

; Open XML database in XML Viewer
ViewDatabase() {
	global DOM

	if DOM.documentElement {
		; View XML document
		DOM.viewXML()
	}
}

; Save database to file
SaveDatabase() {
	global DOM
	global DBPath

	if DOM.documentElement {
		DOM.save(DBPath)
	}
}

; end of DATABASE MANAGEMENT
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; VARIOUS FUNCTIONS

; Sort an array using an another array
; One array can be made of anything, second one must be an array of numbers
UndercoverArraySort(MainArray, HelperArray) {
	If ( HelperArray.MaxIndex() != MainArray.MaxIndex() ) {
		MsgBox Arrays not equal length!
		Return
	}

	NewHelperArray := []
	NewMainArray := []

	for mainIndex, mainElement in HelperArray
	{
		If ( A_Index = 1 ) {
			NewHelperArray.Push( HelperArray[mainIndex] )
			NewMainArray.Push( MainArray[mainIndex] )

			continue
		}

		for subIndex, subElement in NewHelperArray
		{
			If ( mainElement > subElement ) {
				NewHelperArray.Insert( subIndex, HelperArray[mainIndex] )
				NewMainArray.Insert( subIndex, MainArray[mainIndex] )

				break
			}

			If (subIndex = NewHelperArray.MaxIndex()) {
				NewHelperArray.Push( HelperArray[mainIndex] )
				NewMainArray.Push( MainArray[mainIndex] )

				break
			}
		}
	}

	Return NewMainArray
}

; https://autohotkey.com/board/topic/70202-string-compare-function-nonstandard-method/
StringCompare(StringA, StringB, CaseSense=False, Digits=8) {
	Loop %Digits%
		Max .= 9, Zeros .= 0
	If (CaseSense and StringA == StringB) or (!CaseSense and StringA = StringB)
		Return Max
	Score := 0, SearchLength := 0, LengthA := StrLen(StringA), LengthB := StrLen(StringB)
	Loop % (LengthA < LengthB ? LengthA : LengthB) * 2 {
		If (A_Index & 1)
			SearchLength += 1, Needle := "A", Haystack := "B"
		Else
			Needle := "B", Haystack := "A"
		StartAtHaystack := 1, StartAtNeedle := 1
		While (StartAtNeedle + SearchLength <= Length%Needle% + 1)
			If (Pos := InStr(String%Haystack%, SubStr(String%Needle%, StartAtNeedle, SearchLength), CaseSense, StartAtHaystack)) {
				StartAtHaystack := Pos + SearchLength, StartAtNeedle += SearchLength, Score += SearchLength ** 2
				If (StartAtHaystack + SearchLength > Length%Haystack% + 1)
					Break
			} Else
				StartAtNeedle += 1
	}
	Return (Score := Round(Score * 10 ** (Digits // 2) / (LengthA > LengthB ? LengthA : LengthB))) >= Max ? Max - 1 : SubStr(Zeros Score, 1 - Digits)
}

; Concat array of strings into one string
ConcatStringArray(Array, Separator) {
	string := ""

	for index, value in Array
	{
		string .= value
		string .= Separator
	}

	return string
}

; Find an index of first occurence of string in an array of strings
GetInStrArrayIndex(Array, Phrase) {
	for index, value in Array
	{
		if InStr(value, Phrase, false)
			return index
	}

	return -1
}

; Remove duplicate entries from array
RemoveDuplicates(Array) {
	NewArray := [], TestArray := []

	for index, value in Array
	{
		if !TestArray.HasKey(value)
		{
			; Create an associative array entry in order to use HasKey
			TestArray[value] := true
			; Move entry to uniques entries array
			NewArray.Push(value)
		}
	}

	return NewArray
}

; Get index of item inside array
ObjectIndexOf(Object, Item, CaseSensitive:=false) {
	for index, value in Object {
		if (CaseSensitive ? (value == Item) : (value = Item))
			return index
	}
}

; Create an array of provided size filled with provided item
CreateFilledArray(Size, Item) {
	TempArray := []

	; Populate as many array cells as needed with the item
	Loop % Size {
		TempArray[A_Index] := Item
	}

	return TempArray
}

; Get an array and leave only those items which appears required amount of times
GetOccurencesArray(Array, RequiredCount) {
	; First create an array of unique entries
	TrimmedArray := RemoveDuplicates(Array)
	; Prepare a filled array with 0's in which I'm going to store number of occurences of an item
	CountArray := CreateFilledArray(TrimmedArray.MaxIndex(), 0)

	; Iterate through unique array of elements
	for index, unique in TrimmedArray
	{
		; Mark count of each elements occurence from main array inside count array
		while ObjectIndexOf(Array, TrimmedArray[index]) > 0
		{
			Array.remove(ObjectIndexOf(Array, TrimmedArray[index]))
			CountArray[index] += 1
		}
	}

	UniqueDupArray := []

	; Check which elements occurs required amount of times and copy them onto final output array
	for index, value in CountArray
	{
		If CountArray[index] = RequiredCount
		{
			UniqueDupArray.Push(TrimmedArray[index])
		}
	}

	return UniqueDupArray
}

; https://www.autohotkey.com/boards/viewtopic.php?t=60522
Obj2String(Obj,FullPath:=1,BottomBlank:=0){
	static String,Blank
	if(FullPath=1)
		String:=FullPath:=Blank:=""
	if(IsObject(Obj)){
		for a,b in Obj{
			if(IsObject(b))
				Obj2String(b,FullPath "." a,BottomBlank)
			else{
				if(BottomBlank=0)
					String.=FullPath "." a " = " b "`n"
				else if(b!="")
					String.=FullPath "." a " = " b "`n"
				else
					Blank.=FullPath "." a " =`n"
			}
	}}
	return String Blank
}

; end of VARIOUS FUNCTIONS
;-------------------------------------------------------------------------------

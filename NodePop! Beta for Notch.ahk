;-------------------------------------------------------------------------------
; PROJECT NAME: NodePop! Beta ;)
; DESCRIPTION: a node spawner for Notch
; COMPATIBLE WITH NOTC VERSION: 0.9.22.065

; USAGE: Hit Ctrl+Space while Notch-ing, write the name of a node in popup window (or use an abbreviation), hit Enter and Pop!
;		 Right click on tray icon and go to settings - you can set there hotkeys for specific node's spawning.
;
; crafted by Martin Winged @ Piloci Studio
;-------------------------------------------------------------------------------



#Persistent ; This keeps the script running permanently.
#SingleInstance Force ; Only allows one instance of the script to run.
#WinActivateForce
SetTitleMatchMode, 2 ; A window's title can contain WinTitle anywhere inside it to be a match
CoordMode, Mouse, Screen ; Check on what screen mouse is right now - needed for testing window focus
SetBatchLines, -1
SetWinDelay, 0

; Debug mode OFF/ON
DEBUG_MODE = 0
DebugCounter = 0



;-------------------------------------------------------------------------------
; INITIALIZATION OF GLOBAL VARIABLES

; Load large icon image for settings menu
nodepop_image = %A_ScriptDir%\include\nodepop.png

; Load icon image
nodepop_ico = %A_ScriptDir%\include\nodepop.ico



	;-------------------------------------------------------------------------------
	; MENU PREPARING

; Turn off default AHK tray options
Menu, Tray, NoStandard
Menu, Tray, Icon, %nodepop_ico%

; Create main tray menu
Menu, Tray, Add, Settings, MenuSettings
Menu, Tray, Add, Exit, MenuExit

; Exit application from tray menu
MenuExit()
{
	ExitApp
}

	; end of MENU PREPARING
	;-------------------------------------------------------------------------------



	;-------------------------------------------------------------------------------
	; PREPARE DATABASE

; Specify path to RAW database file
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

	; end of PREPARE DATABASE
	;-------------------------------------------------------------------------------



; Array of most commonly used nodes
; CommonNodes[index]: reference to Nodes[] element
CommonNodes := []

; Array of favourite nodes spawnable by keyboard shortcuts
; FavouriteNodes[index]: {
;	"nodeID": "none" OR <1, Nodes.MaxIndex()
;	"shortcut": "none" OR f.e. "^1"
;	"db": "none" OR XML reference
; }
FavouriteNodes := []

; Array of all nodes
; Nodes[index]: {
;	"name_str": f.e. "Cylindrical Camera (Cameras)"
;	"name_arr": f.e. ["Cylindircal" "Camera" "(Cameras)"]
;	"position": /integer/ <1, +>
;	"frequency": /integer/ <0, +>
;	"nodeID": <1, Nodes.MaxIndex()
;	"db": XML reference
; }
Nodes := []

; Any extra options
ExtrasOption := {}

; Count number of nodes spawned
SpawnCounter := 0

; Identificator of currently modifying favourite node
CurrentFavEdit := 0

; Variable to store active Notch window PID
NotchWindowPID := ""
GUIWindowPID := ""

; Load favourite nodes
InitializeDatabase()

if (DEBUG_MODE)
	ResetDatabase()

Return

; end of INITIALIZATION OF GLOBAL VARIABLES
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; SETTINGS MENU

; Display settings menu subroutine
MenuSettings:
	; Destroy any previously opened GUI
	Gui, Destroy

	Gui, Add, Tab3,, Settings|About
	Gui, Tab, 1
	Gui, Margin, 9, 9

; Favourite nodes tab
	; Favourite hotkey 1
	Gui, Add, GroupBox, x10 y30 w240 h65, Favourite Slot 1
	Gui, Add, Text, x20 y50 w220 vFavNodeName1,
	Gui, Add, Text, x20 y+5 w220 vFavNodeShortcut1,
	Gui, Add, Button, x260 y43 w50 vCleanFav1 gCleanFavouriteButton, Clean
	Gui, Add, Button, x260 y67 w50 vModFav1 gModifyFavouriteButton, Modify

	; Favourite hotkey 2
	Gui, Add, GroupBox, x10 y110 w240 h65, Favourite Slot 2
	Gui, Add, Text, x20 y130 w220 vFavNodeName2,
	Gui, Add, Text, x20 y+5 w220 vFavNodeShortcut2,
	Gui, Add, Button, x260 y123 w50 vCleanFav2 gCleanFavouriteButton, Clean
	Gui, Add, Button, x260 y147 w50 vModFav2 gModifyFavouriteButton, Modify

	; Favourite hotkey 3
	Gui, Add, GroupBox, x10 y185 w240 h65, Favourite Slot 3
	Gui, Add, Text, x20 y205 w220 vFavNodeName3,
	Gui, Add, Text, x20 y+5 w220 vFavNodeShortcut3,
	Gui, Add, Button, x260 y198 w50 vCleanFav3 gCleanFavouriteButton, Clean
	Gui, Add, Button, x260 y222 w50 vModFav3 gModifyFavouriteButton, Modify

	; Favourite hotkey 4
	Gui, Add, GroupBox, x10 y260 w240 h65, Favourite Slot 4
	Gui, Add, Text, x20 y280 w220 vFavNodeName4,
	Gui, Add, Text, x20 y+5 w220 vFavNodeShortcut4,
	Gui, Add, Button, x260 y273 w50 vCleanFav4 gCleanFavouriteButton, Clean
	Gui, Add, Button, x260 y297 w50 vModFav4 gModifyFavouriteButton, Modify

	; Favourite hotkey 5
	Gui, Add, GroupBox, x10 y335 w240 h65, Favourite Slot 5
	Gui, Add, Text, x20 y355 w220 vFavNodeName5,
	Gui, Add, Text, x20 y+5 w220 vFavNodeShortcut5,
	Gui, Add, Button, x260 y348 w50 vCleanFav5 gCleanFavouriteButton, Clean
	Gui, Add, Button, x260 y372 w50 vModFav5 gModifyFavouriteButton, Modify

	; Separator line
	Gui, Add, Text, x20 y410 w290 0x10

	Gui, Add, Checkbox, x20 y420 vSpellingCorrectionMode gToggleTypoMode, EXTRA: Spelling-correction mode (slower)

	Gui, Add, Button, x112 y+20 w90 gApplySettings, Save and Close

	GoSub, FillMenuInfo

; About tab
	Gui, Tab, 2

	; Add big program icon
	Gui, Add, Picture, x40 y40 w250 h250, %nodepop_image%

	Gui, Add, Text, x125 y300 , NodePop! Beta
	Gui, Add, Text, x87 y+5 , a smart node spawner for Notch
	Gui, Add, Text, x67 y+5 , Compatible with Notch version: 0.9.22.065
	Gui, Add, Text, x37 y+10 , press Ctrl+Space, type in phrases, press Enter and Pop!

	Gui, Add, Text, x65 y+40 , crafted by Martin Winged @ Piloci Studio
	Gui, Add, Text, x102 y+5 , patreon.com/martinwinged
	Gui, Add, Text, x115 y+5 , tomek@pilocistudio.pl
	Gui, Add, Text, x120 y+5 , www.pilocistudio.pl
	;Gui, Add, Button, x120 y+100 gResetDatabaseButton, Reset Database

	; Display GUI
	Gui, Show, , NodePop! Beta > Settings
Return

; Use checkbox to toggle between spell-correction mode
ToggleTypoMode:
	Gui, Submit, NoHide
	ExtrasOption["Spelling Correction"].value := SpellingCorrectionMode
Return

; Read data from runtime arrays and fill labels and so on
FillMenuInfo:
	for index, element in FavouriteNodes
	{
		label_name := "FavNodeName" index
		label_shortcut := "FavNodeShortcut" index

		If (element["nodeID"] != "none") {
			NodeID := element["nodeID"]
			Shortcut := element["shortcut"]

			; Replace AHK's controls naming to human readable ones
			If InStr(Shortcut, "+")
				Shortcut := StrReplace(Shortcut, "+", "Shift+")
			If InStr(Shortcut, "^")
				Shortcut := StrReplace(Shortcut, "^", "Ctrl+")
			If InStr(Shortcut, "!")
				Shortcut := StrReplace(Shortcut, "!", "Alt+")

			GuiControl,, % label_name, % "Node: " Nodes[NodeID]["name_str"]
			GuiControl,, % label_shortcut, % "Shortcut: " Shortcut
		}
		Else
		{
			GuiControl,, % label_name, % "Node: none"
			GuiControl,, % label_shortcut, % "Shortcut: none"
		}
	}

	; Extras checkbox
	GuiControl,, SpellingCorrectionMode, % ExtrasOption["Spelling Correction"].value
Return

; Reset all database values to default
ResetDatabaseButton:
	ResetDatabase()

	; Refresh menu
	Gui, Destroy

	TrayTip
	TrayTip, Factory reset, Database restored to default values, 3

	GoSub, MenuSettings	
Return

; Clear favourite entry in runtime arrays
CleanFavouriteButton:
	; Get last char from A_GuiControl - f.e. vCleanFav4 = 4
	FavNumber := SubStr(A_GuiControl, 0, 1)

	Shortcut := FavouriteNodes[FavNumber]["shortcut"]

	If (Shortcut = "none")
		Return

	; Turn off hotkey
	UpdateHotkey(FavNumber, Shortcut, "Off")

	; Clean FavouriteNodes array entry
	FavouriteNodes[FavNumber]["nodeID"] := "none"
	FavouriteNodes[FavNumber]["shortcut"] := "none"

	; Refresh menu
	Gui, Destroy

	GoSub, MenuSettings
Return

ModifyFavouriteButton:
	; Get last char from A_GuiControl - f.e. vCleanFav4 = 4
	FavNumber := SubStr(A_GuiControl, 0, 1)

	CurrentFavEdit := FavNumber

	; Destroy all GUI before showing next one
	Gui, Destroy

	; Create text box where you can write node names
	Gui, Add, Text, x5 y7, Node name:
	Gui, Add, Edit, x70 y5 w250 h20 hwndhMyText vTypedText gOnTextEdit,

	; Create list of available node names
	; +AltSubmit retrieves selected item index instead of it's name "GuiControlGet, MyVar, , ListBox"
	Gui, Add, ListBox, x70 y25 w250 r5 vListBox +AltSubmit

	Gui, Add, Text, x350 y7, Shortcut:
	Gui, Add, Hotkey, x400 y5 w50 h20 vHK

	Gui, Add, Button, x350 y48 w100 h20 gApplyModify, Apply
	Gui, Add, Button, x350 y73 w100 h20 gCancelModify, Cancel

	Gui, Show,, NodePop! > Modify Slot %FavNumber%
Return

ApplyModify:
	; Retrieve the selections
	GuiControlGet, NodeNameSelection, , ListBox
	GuiControlGet, ShortcutSelection, , HK

	; Check if hotkey has been selected, if no, do nothing
	if not ShortcutSelection
		Return

	; Check if node name has been selected, if no, do nothing
	if not NodeNameSelection > 0
		Return

	For index, element in FavouriteNodes
	{
		; Check if this node is already binded
		If (element["nodeID"] = ListResult[NodeNameSelection]["nodeID"])
		{
			TrayTip
			TrayTip, This node is already binded!, Unbind it first, 3
			Return
		}

		; Check if hotkey combination is already binded
		If (element["shortcut"] == ShortcutSelection)
		{
			TrayTip
			TrayTip, Hotkey combination is already in use!, Unbind it first, 3
			Return
		}
	}

	; Update FavouriteNodes array
	FavouriteNodes[CurrentFavEdit]["nodeID"] := ListResult[NodeNameSelection]["nodeID"]
	FavouriteNodes[CurrentFavEdit]["shortcut"] := ShortcutSelection

	; Turn on hotkey for this favourite
	UpdateHotkey(CurrentFavEdit, ShortcutSelection, "On")

	; Close GUI
	Gui, Destroy
	Gosub, MenuSettings
Return

CancelModify:
	Gui, Destroy
	Gosub, MenuSettings
Return

ApplySettings:
	; Update entires in XML database
	UpdateDatabase()

	; Save updated version of databse to file
	SaveDatabase()

	Gui, Destroy
Return

GuiClose:
	Gui, Destroy
return

; end of SETTINGS MENU
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; FAVOURITE NODES HOTKEYS

; Turn hotkey on or off
UpdateHotkey(hotkey_number, hotkey_shortcut, state = "On") {
	Hotkey, % hotkey_shortcut, % "FavHotkey" hotkey_number, % state
}

FavHotkey1:
	Winget, AppName, ProcessName, A
	If ( AppName = "NotchApp.exe" ) {
		; If favourite node has not been binded yet
		If (FavouriteNodes[1]["nodeID"] == "none")
		{
			TrayTip, Not so fast, Assign your favourite node shortcut first!
			Return
		}

		SpawnNode( Nodes[FavouriteNodes[1]["nodeID"]] )
	}
Return

FavHotkey2:
	Winget, AppName, ProcessName, A
	If ( AppName = "NotchApp.exe" ) {
		; If favourite node has not been binded yet
		If (FavouriteNodes[2]["nodeID"] == "none")
		{
			TrayTip, Not so fast, Assign your favourite node shortcut first!
			Return
		}

		SpawnNode( Nodes[FavouriteNodes[2]["nodeID"]] )
	}
Return

FavHotkey3:
	Winget, AppName, ProcessName, A
	If ( AppName = "NotchApp.exe" ) {
		; If favourite node has not been binded yet
		If (FavouriteNodes[3]["nodeID"] == "none")
		{
			TrayTip, Not so fast, Assign your favourite node shortcut first!
			Return
		}

		SpawnNode( Nodes[FavouriteNodes[3]["nodeID"]] )
	}
Return

FavHotkey4:
	Winget, AppName, ProcessName, A
	If ( AppName = "NotchApp.exe" ) {
		; If favourite node has not been binded yet
		If (FavouriteNodes[4]["nodeID"] == "none")
		{
			TrayTip, Not so fast, Assign your favourite node shortcut first!
			Return
		}

		SpawnNode( Nodes[FavouriteNodes[4]["nodeID"]] )
	}
Return

FavHotkey5:
	Winget, AppName, ProcessName, A
	If ( AppName = "NotchApp.exe" ) {
		; If favourite node has not been binded yet
		If (FavouriteNodes[5]["nodeID"] == "none")
		{
			TrayTip, Not so fast, Assign your favourite node shortcut first!
			Return
		}

		SpawnNode( Nodes[FavouriteNodes[5]["nodeID"]] )
	}
Return

; end of FAVOURITE NODES ACTIONS
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
; MAIN MENU

$^Space::
	; Check if Notch window is active
	Winget, AppName, ProcessName, A
	If ( AppName != "NotchApp.exe" ) {
		Send, ^{Space}
		Return
	}

	; Store PID of active Notch window
	WinGet, NotchWindowPID, PID, A

	; Destroy any previously opened GUI
	Gui, Destroy

	; Set GUI font and colors
	Gui, Font, q2 s8 cBEBEBE, Arial
	Gui, Color , 2D2D2D, 282828
	Gui, Margin , 5, 2

	; Create text box where you can write node names
	Gui, Add, Edit, x27 y5 w228 h20 hwndhMyText vTypedText gOnTextEdit,

	; Add exit button
	Gui, Add, Button, x5 y5 w20 h20 gExit, X

	; Create list of available node names
	; +AltSubmit retrieves selected item index instead of it's name "GuiControlGet, MyVar, , ListBox"
	Gui, Add, ListBox, x5 w250 r5 vListBox gListBox +AltSubmit -VScroll

	; Create invisible button to send GUI result using Enter
	Gui, Add, Button, default h0 w0 gAcceptNodeSelection,

	; Hide window header and hide window from taskbar
	Gui, -Caption +E0x08000000

	; Get current mouse position and spawn GUI there
	MouseGetPos, OutputVarX, OutputVarY	
	Gui, Show, x%OutputVarX% y%OutputVarY%

	WinGet, GUIWindowPID, PID, A

	; Update list of most frequently used nodes
	RefreshCommonNodes()

	; Show most frequently used nodes
	ListResult := []

	For index, value in CommonNodes
	{
		ListResult.Push(value)
	}

	ArrayToListBox(ListResult, ListBox)

	; Keep first index in ListBox selection
	GuiControlGet, MyVar, , ListBox
	GuiControl, Choose, ListBox, 1
Return

AcceptNodeSelection:
	; Retrieve the ListBox's current selection and save to variable
	GuiControlGet, MyVar, , ListBox

	if not MyVar > 0
		Return

	; Destroy GUI
	Gui, Destroy

	; Spawn node
	SpawnNode(ListResult[MyVar])
Return

OnTextEdit:
	; Get the info entered in the GUI
	Gui, Submit, NoHide

	; If there is no text typed
	If StrLen(TypedText) < 1
	{
		; Show most frequently used nodes
		ListResult := []

		For index, value in CommonNodes
		{
			ListResult.Push(value)
		}

		ArrayToListBox(ListResult, ListBox)

		Return
	}

	; Prepare array for text matches
	ListResult := []

	; Split input string into words and check all words against Nodes names
	WordArray := StrSplit(TypedText, A_Space, ".")

	; Pass all node names through String Similarity algorithm
	if (ExtrasOption["Spelling Correction"].value = 1) {
		; Iterate through all node names array
		for index, element in Nodes
		{
			ListResult.Push(element)
		}

		ListResult := SortListResult(TypedText)
	}
	; Show and sort only results that matches typed text; sorting based on frequency usage
	else {
		FrequencyArrayHelper := []
		; Iterate through all node names array
		for index, element in Nodes
		{
			; Make a temp name array variable to freely work on it later
			TempNodeName := element["name_arr"].Clone()
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
				ListResult.Push(element)
				FrequencyArrayHelper.Push(element["frequency"])
			}
		}

		; Sort output array based on frequency node spawning
		ListResult := UndercoverArraySort(ListResult, FrequencyArrayHelper)
		
		; TODO: After sorting by frequency sort by name name string length - shorter in front
	}

	; Update listbox
	ArrayToListBox(ListResult, ListBox)

	; Keep first index in ListBox selection
	GuiControlGet, MyVar, , ListBox
	GuiControl, Choose, ListBox, 1
Return

Exit:
	Gui, Destroy
Return

; Use arrow Up to move in ListBox
$Up::
	; If script window is not active, passthrough keystroke
	IfWinNotActive, ahk_pid %GUIWindowPID%
	{
		Send, {Up}
		Return
	}

	; Get current ListBox selection
	GuiControlGet, MyVar, , ListBox
	Selection := MyVar

	If Selection > 1
	{
		Selection -= 1
		GuiControl, Choose, ListBox, %Selection%
	}
	Else
	{
		GuiControl, Choose, ListBox, 1
	}
Return

; Use arrow Down to move in ListBox
$Down::
	; If script window is not active, passthrough keystroke
	IfWinNotActive, ahk_pid %GUIWindowPID%
	{
		Send, {Down}
		Return
	}

	; Get current ListBox selection
	GuiControlGet, MyVar, , ListBox
	Selection := MyVar

	If Selection > 0
	{
		Selection += 1
		GuiControl, Choose, ListBox, %Selection%
	}
	Else
	{
		GuiControl, Choose, ListBox, 1
	}
Return

; If script window is selected, use Esc to close menu
$Esc::
	; If script window is not active, passthrough keystroke
	IfWinNotActive, ahk_pid %GUIWindowPID%
	{
		Send, {Esc}
		Return
	}

	Gui, Destroy
Return

; Use Alt+NumpadAdd to spawn next node while debug mode
$!NumpadAdd::
	if not DEBUG_MODE {
		Send, {NumpadAdd}
		Return
	}

	; Increment debug counter
	DebugCounter++
	
	if (DebugCounter > Nodes.MaxIndex()) {
		DebugCounter--
		return
	}
	

	; Show popup
	MsgBox % DebugCounter . ": " . Nodes[DebugCounter].name_str
	SpawnNode(Nodes[DebugCounter])
	
	; Set clipboard to pasted node string name
	clipboard := SubStr(Nodes[DebugCounter].name_str, 1 , InStr(Nodes[DebugCounter].name_str, "(") - 2)
Return

; Use Alt+NumpadSub to spawn previous node while debug mode
$!NumpadSub::
	if not DEBUG_MODE {
		Send, {NumpadSub}
		Return
	}
	
	; Decrement debug counter
	DebugCounter--
	
	if (DebugCounter < 1) {
		DebugCounter++
		return
	}
	
	; Show popup
	MsgBox % DebugCounter . ": " . Nodes[DebugCounter].name_str
	SpawnNode(Nodes[DebugCounter])
	
	; Set clipboard to pasted node string name
	clipboard := SubStr(Nodes[DebugCounter].name_str, 1 , InStr(Nodes[DebugCounter].name_str, "(") - 2)
Return

; Handle double click on list item
ListBox:
	; If not double clicked do nothing
	if A_GuiControlEvent <> DoubleClick
	return

	; Retrieve the ListBox's current selection and save to variable
	GuiControlGet, MyVar, , ListBox

	if not MyVar > 0
		Return

	; Destroy GUI
	Gui, Destroy

	; Spawn node
	SpawnNode(ListResult[MyVar])
Return


; end of MAIN MENU
;-------------------------------------------------------------------------------

; Do some keystrokes in order to spawn provided node name onto nodegraph
; Use clipbaord to paste quickly node name instead of slowly typing it
SpawnNode(NodeInfo) {
	global NotchWindowPID
	global SpawnCounter

	; Focus on Notch window
	WinActivate ahk_pid %NotchWindowPID%

	; Wait for Notch window to become active
	WinWaitActive ahk_pid %NotchWindowPID%

	name := NodeInfo["name_str"]
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
	Loop % NodeInfo["position"]
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
	NodeInfo["frequency"] += 1
	NodeInfo["db"].setAttribute("frequency", NodeInfo["frequency"])

	SpawnCounter += 1

	; Save database every 10 spawned nodes
	If ( Mod(SpawnCounter, 10) = 0 ) {
		SaveDatabase()
	}
}

; Refresh list of the most common nodes
RefreshCommonNodes() {
	global Nodes
	global CommonNodes

	; Clean array
	CommonNodes := []

	; Iterate through every node info and compare it's usage frequency
	for index, element in Nodes
	{
		; Populate marray with any nodes to compare with them later
		If (CommonNodes.MaxIndex() < 5) {
			CommonNodes.Push(Nodes[A_Index])
			continue
		}

		; Choose 5 most common nodes
		Loop, 5
		{
			If element["frequency"] > CommonNodes[A_Index]["frequency"]
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

; Update listbox with passed array of strings
ArrayToListBox(Array, ListBox) {
	; Start combined string for ListBox with | in order to replace entires
	combined := "|"

	For index, value in Array
	{
		name := value["name_str"]
		combined = %combined%%name%
		combined = %combined%|
	}

	; Update ListBox with combined array
	GuiControl, , ListBox, % combined
}

SortListResult(TypedText) {
	global ListResult

	SimilarityArray := []

	for index, element in ListResult
	{
		SimilarityArray.Push(StringCompare(TypedText, element["name_str"]))
	}

	Return UndercoverArraySort(ListResult, SimilarityArray)
}

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

;-------------------------------------------------------------------------------
; DATABASE LOADING AND MANAGEMENT FUNCTIONS

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
					NodeFrequency := Node.getAttribute("frequency")
					NodeID := Node.getAttribute("ID")

					; Prepare category string for displaying in ListBox
					CategoryDisplayedName := ""
					If (SubcategoryStr == "Root")
						CategoryDisplayedName .= CategoryStr
					Else
						CategoryDisplayedName .= CategoryStr " > " SubcategoryStr

					; Assemble whole displayed node name in ListBox
					NodeDisplayName := NodeNameStr " (" CategoryDisplayedName ")"

					; Push complete node info to main Nodes array
					OutputArray.Push( {"name_str": NodeDisplayName, "name_arr": StrSplit(NodeDisplayName, A_Space), "position": NodePositionVal, "frequency": NodeFrequency, "db": Node, "nodeID": NodeID} )
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
					OutputArray[A_Index] := {"nodeID": "none", "shortcut": "none", "db": "none"}

					; If slot is assigned
					If ( ( NodeID != "none" ) && ( SlotShortcut != "none" ) ) {
						; Put this info into OutputArray
						OutputArray[A_Index]["nodeID"] := NodeID
						OutputArray[A_Index]["shortcut"] := SlotShortcut

						; Turn on hotkey for this favourite
						UpdateHotkey(A_Index, SlotShortcut, "On")
					}

					; Assign database slot
					OutputArray[A_Index]["db"] := Slot
				}
			}
		}
	}

	Return OutputArray	
}

loadExtrasEntries() {
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
	
	MsgBox, Resetting database!

	; Reset frequency entries and ID's
	for index, element in Nodes
	{
		element["db"].setAttribute("frequency", 0)
		element["db"].setAttribute("ID", index)
	}
	

	; Reset "Favourite Nodes" category
	for index, element in FavouriteNodes
	{
		element["db"].setAttribute("nodeID", "none")
		element["db"].setAttribute("shortcut", "none")
	}

	for index, element in ExtrasOption
	{
		element["db"].setAttribute("value", 0)
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
			element["db"].setAttribute("frequency", element["frequency"])
		}
	}

	If (WhatToUpdate = "favourites" || WhatToUpdate = "all") {
		; Update "Favourite Nodes" category
		for index, element in FavouriteNodes
		{
			element["db"].setAttribute("nodeID", element["nodeID"])
			element["db"].setAttribute("shortcut", element["shortcut"])
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
	ExtrasOption := loadExtrasEntries()
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

; end of DATABASE LOADING AND MANAGEMENT FUNCTIONS
;-------------------------------------------------------------------------------
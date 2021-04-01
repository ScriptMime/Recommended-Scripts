#NoEnv
#SingleInstance, force
#Persistent
SetBatchLines, -1

DetectHiddenWindows, on
SetTitleMatchMode, 2




if(not A_IsAdmin)
{
	run *RunAs "%A_ScriptFullPath%"
	ExitApp
}


/*
	GUI
*/


;;______import files, declare and set variables
#Include ../Neutron.ahk


neutron := new NeutronWindow()
neutron.Load("masterscriptGUI.html")

neutron.Gui("+LabelNeutron")

global scripts, scriptarr, descriptionarr, fullpatharr, filearr, filename, file, scriptpaths


filename := "scripts.txt"
file := FileOpen(filename, "rw")

FileRead, scripts , %filename%

scriptarr := []
descriptionarr := []
fullpatharr := []
filearr := StrSplit(scripts, "`n")



for i, ele in filearr {
	
	if(ele == ""){
		continue
	}
	start := InStr(ele, "*-[")
	end := InStr(ele, "]-*")
	
	;get scriptname in line
	script := SubStr(ele, 1, start - 1)
		
	
	scriptarr.push(script)

	;get description in line
	
	description := SubStr(ele, start +3, end - start - 3)
	
	descriptionarr.push(description)
	
	;get fullpath in line
	
	finalend := InStr(ele, "}=END")
	fullpath := SubStr(ele, end+4, finalend - end -4)
	fullpatharr.push(fullpath)
	
}


;________________REMOVE DUPLICATES
;duplicates for description will be allowed

scriptarr := removeDuplicates(scriptarr)
fullpatharr := removeDuplicates(fullpatharr)




for i, ele in scriptarr {
	

	if(ele == ""){
		continue
	}
	
	
	tempdiv := neutron.doc.createElement("div")
	rowHTML := neutron.FormatHTML("<div class='' id='{}'> <div class='col-sm d-inline'>{}</div> <div class='col-sm d-inline scriptname'>{}</div> <div class='col-sm d-inline description'>{}</div> <div class='col-sm d-inline scriptpath'>{}</div> <div class='col-sm d-inline'><button onclick='ahk.onClickScriptButton(event)' class='btn btn-danger'>x</button></div> </div>",i, i, ele, descriptionarr[i], SubStr(fullpatharr[i], 1, 30) . "..."  )
	tempdiv.innerHTML := rowHTML
	
	neutron.qs("#scriptlist").appendChild(tempdiv)
}






neutron.Show()

window := neutron.hwnd

WinMove, ahk_id %window%,,A_ScreenWidth / 8, A_ScreenHeight / 8, 1500, 1000
return


FileInstall, masterscriptGUI.html, masterscriptGUI.html
FileInstall, bootstrap.min.css, bootstrap.min.css
FileInstall, bootstrap.min.js, bootstrap.min.js
FileInstall, jquery.min.js, jquery.min.js

NeutronClose:
guiClose:

neutron.Destroy()

return




/*
	Helper Functions
*/



removeDuplicates(object) {
secondobject:=[]
Loop % object.Length()
{
	value:=Object.RemoveAt(1) ; otherwise Object.Pop() a little faster, but would not keep the original order
	Loop % secondobject.Length()
		If (value=secondobject[A_Index])
    		Continue 2 ; jump to the top of the outer loop, we found a duplicate, discard it and move on
	secondobject.Push(value)
}
Return secondobject
}



/*
	GUI Functions
*/

addScript(num, script, description, fullpath){
	
	tempdiv := neutron.doc.createElement("div")
	rowHTML := neutron.FormatHTML("<div class='' id='{}'><div class='col-sm d-inline'>{}.</div><div class='col-sm d-inline'>{}</div> <div class='col-sm d-inline'>{}</div> <div class='col-sm d-inline'>{}</div> <div class='col-sm d-inline'><button onclick='ahk.onClickScriptButton(event)' class='btn btn-danger'>x</button ></div> </div>",num, num, script, description, SubStr(fullpath, 1, 30) . "...")
	tempdiv.innerHTML := rowHTML
	
	neutron.qs("#scriptlist").appendChild(tempdiv)
}


submitScriptAdd(neutron, event){
	
	global scripts, filename, file
	event.preventDefault()
	data := neutron.GetFormData(event.target)
	
	scriptstring := data.scriptpathinput , descriptionstring := data.scriptdescriptioninput, fullpathstring := data.scriptfullpathinput
	
	fullpathstring := StrReplace(fullpathstring, """", "")
	scripts .= scriptstring " *-[" descriptionstring "]-* " fullpathstring " }=END"

	
	try {

		file.WriteLine(scripts)
	} catch e {
		MsgBox % e
	}
	
	num := neutron.body.children.length + 1
	addScript(num, scriptstring, descriptionstring, fullpathstring)
	
	sleep, 200
	
	Reload
	
	
	MsgBox % data.scriptpathinput " " data.scriptdescriptioninput
}


onClickScriptButton(neutron, event){

	global scripts, filename, file, fullpatharr

	divid := event.currentTarget.parentNode.parentNode.id
	
	sleep, 50
	
	
	parentdiv := neutron.qs("#scriptlist")
	
	
	for i, ele in neutron.Each(neutron.doc.getElementById("scriptlist").children){
		
		
		if(InStr(ele.innerHTML, "id=" . "'" . divid . "'" ) or InStr(ele.innerHTML, "id=" . """" . divid . """" )){
			
			
			string := ""
			loop, read, %filename% 
			{
				
				if(A_Index == divid){
					continue
				}
				string .= A_LoopReadLine "`n"
			}
			sleep, 10
			FileDelete, %filename%
			sleep, 10
			
			FileAppend, %string%, %filename%
			
			parentdiv.removeChild(ele)
			
			fullpatharr.RemoveAt(divid)
			
			
			
			;~ sleep, 200
			;~ Reload

		}
	}
}

onClickChangeMasterRun(neutron, event){
	MsgBox, Open this directory and edit your file: %A_ScriptDir%
	
}

onClickChangeMasterReload(neutron, event){
	MsgBox, Open this directory and edit your file: %A_ScriptDir%

}

/*
	Master Hotkeys/strings 
*/

;run all scripts

:*:master_run::         ;;CHANGE THIS to a hotkey or hotstring

for index, element in fullpatharr
{
	;~ MsgBox % element
	run %element% 
}

return


;stop and kill all Autohotkey programs running except this script

:*:master_reload::       ;;CHANGE THIS to a hotkey or hotstring

WinGet, List, List, ahk_class AutoHotkey 

Loop %List% 
  { 
    WinGet, PID, PID, % "ahk_id " List%A_Index% 
    If ( PID <> DllCall("GetCurrentProcessId") ) 
         PostMessage,0x111,65405,0,, % "ahk_id " List%A_Index% 
  }
return


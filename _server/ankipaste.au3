#WinActivateForce
Opt("WinTitleMatchMode", 4)

WinActivate("[REGEXPTITLE:kanji.* - Anki]")
Sleep(200)

WinWaitActive("[REGEXPTITLE:kanji.* - Anki]","",4)
If WinActive("[REGEXPTITLE:kanji.* - Anki]") <> 0 Then
  Send("^e")
  Send("^a")
  Send("^v")
#  Send("{ESCAPE}")
#  Send(" ")
EndIf

'
' Sample Script
'
' This script contains the basic logging information that I use everywhere
'
	Call LogData(4, ScriptDetails(".") & vbCrLf & "Started: " & Now())
	Call ListNet(".")
	Call LogData(4, ScriptDetails(".") & vbCrLf & "Finished: " & Now())

Sub ListNet(strComputer)
	On Error Resume Next
	'
	' List the MAC and IP's of IP enabled Network Adapters
	'
	Dim objWMIService
	Dim colItems
	Dim objItem
	Dim strIP
	Dim strIPAddress
	Dim strIPv4
	Dim strIPv6

	Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2") 
	If Err <> 0 Then 
		Call HandleError(Err.Number, Err.Description)
	End If
	Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration Where IPEnabled = True",,48) 
	If Err <> 0 Then 
		Call HandleError(Err.Number, Err.Description)
	End If

		For Each objItem in colItems
			strMac = objItem.MACAddress
			strIPAddress = objItem.IPAddress
			For Each strIP in strIPAddress
			    If inStr(strIP, ".") Then
			       strIPv4 = strIP
			    End If
			    If inStr(strIP, ":") Then
			       strIPv6 = strIP
			    End If
			Next
			Wscript.Echo "MAC: " & strMac
			Wscript.Echo "IP4: " & strIPv4
			Wscript.Echo "IP6: " & strIPv6

			Wscript.echo
		Next

End Sub

Sub LogData(intCode, strMessage)
	' Write data to application log
	' 
	' http://www.microsoft.com/technet/scriptcenter/guide/default.mspx?mfr=true
	'
	' Event Codes
	' 	0 = Success
	'	1 = Error
	'	2 = Warning
	'	4 = Information
	Dim objShell

	Set objShell = Wscript.CreateObject("Wscript.Shell")

		objShell.LogEvent intCode, strMessage

End Sub

Function ScriptDetails(strComputer)
	'
	' Return information about who, what, where
	'
	On Error Resume Next
	Dim strScriptName
	Dim strScriptPath
	Dim strUserName
	Dim objWMIService
	Dim colProcesslist
	Dim objProcess
	Dim colProperties
	Dim strNameOfUser
	Dim struserDomain
	
	strScriptName = Wscript.ScriptName
	strScriptPath = Wscript.ScriptFullName
	
	Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
	Set colProcessList = objWMIService.ExecQuery("Select * from Win32_Process Where Name = 'cscript.exe' or Name = 'wscript.exe'")
	
		For Each objProcess in colProcessList
			If InStr(objProcess.CommandLine, strScriptName) Then
				colProperties = objProcess.GetOwner(strNameOfUser,strUserDomain)
				If Err <> 0 Then
					Call LogData(1, "Error Number: " & vbTab & Err.Number & vbCrLf & "Error Description: " & vbTab & Err.Description)
					Err.Clear
					Exit For
				End If
				strUserName = strUserDomain & "\" & strNameOfUser
			End If
		Next
	
		ScriptDetails = "Script Name: " & strScriptName & vbCrLf & "Script Path: " & strScriptPath & vbCrLf & "Script User: " & strUserName
End Function

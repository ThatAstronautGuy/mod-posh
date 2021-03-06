'
' Find HelpAssistant
'
' This script searches through AD for computer accounts. It then connects
' to each computer and attempts to determine if the HelpAssistant account
' is enabled.
'
' objUser.AccountDisabled = 0 User Account Enabled
' objUser.AccountDisabled = -1 User Account Disabled
'

	Call LogData(4, ScriptDetails(".") & vbCrLf & "Started: " & Now())
	Call QueryAD("SELECT DistinguishedName ,Name FROM 'LDAP://OU=dummy,DC=company,DC=com' WHERE objectClass = 'computer'")
	Call LogData(4, ScriptDetails(".") & vbCrLf & "Finished: " & Now())

Sub QueryAD(strQuery)
	On Error Resume Next
	'
	' This procedure will loop through a recordset of objects
	' returned from a query.
	'
	Const ADS_SCOPE_SUBTREE = 2
	Dim objConnection
	Dim objCommand
	Dim objRecordset
	Dim Account
	Account = "HelpAssistant"

	
	Set objConnection = CreateObject("ADODB.Connection")
	Set objCommand =   CreateObject("ADODB.Command")
	objConnection.Provider = "ADsDSOObject"
	objConnection.Open "Active Directory Provider"
	
	Set objCOmmand.ActiveConnection = objConnection
	objCommand.CommandText = strQuery
	objCommand.Properties("Page Size") = 1000
	objCommand.Properties("Searchscope") = ADS_SCOPE_SUBTREE 
	Set objRecordSet = objCommand.Execute
	If Err <> 0 Then Call LogData(1, "Unable to connect using the provided query: " & vbCrLf & strQuery)
	
		objRecordSet.MoveFirst
	
		Do Until objRecordSet.EOF
			Call FindUsers(objRecordSet.Fields("Name"))
			If AccountEnabled(Account, objRecordSet.Fields("Name")) = vbTrue Then
					Wscript.Echo Account & " account found enabled on " & objRecordSet.Fields("Name")
				Else
			End If
			objRecordSet.MoveNext
		Loop
End Sub

Function AccountEnabled(strUserName, strComputer)
	'
	' This function returns True if the specified account is found and enabled.
	'
	Dim locUsers
	Dim objUser
	Dim strUser
	
	Set locUsers = GetObject("WinNT://" & strComputer & "")
	locUsers.Filter = Array("user")
	
	For Each objUser In locUsers
		strUser = objUser.Name
		Select Case strUser
			Case strUserName
				AccountEnabled = vbFalse
				If objUser.AccountDisabled = 0 Then
					AccountEnabled = vbTrue
				End If
			Case Else
		End Select
	Next
End Function

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
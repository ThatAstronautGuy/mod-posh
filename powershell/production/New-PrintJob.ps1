<#
    .SYNOPSIS
        Log a print job to a file.
    .DESCRIPTION
        This script works in conjunction with an Event Trigger on the PrintService
        event on our print servers. This script queries the Microsoft-Windows-PrintService/Operational
        log for EventID 307, and returns the drive letter from the most recent event. 
        
        This should be the same event that triggered this script to
        run in the first place.
        
        This script will read in the output of the Get-PrintJobId script and use that to 
        store the value of copies in the database as well as in the log file.
        
        It appends to a CSV log file if it exists, or creates a new file if it doesn't.
    .PARAMETER FileName
        The fully qualified path and filename for the report.
    .PARAMETER FilePath
        The path to where the files should be stored.
    .PARAMETER eventRecordID
        This value is passed in from the even that triggered the task. This is the
        record number of the event in the log. This is used to grab the specific
        event that the script will query data from.
    .PARAMETER eventChannel
        This is the name of the log, as passed in from the Event subsystem.
    .EXAMPLE
        P:\Scripts\New-PrintJob.ps1 -eventRecordID $(eventRecordID) -eventChannel $(eventChannel)
        
        Description
        -----------
        This is how you would call the script when you attach it to an Event Triggered Task.
    .NOTES
        ScriptName: New-PrintJob.ps1
        Created By: Jeff Patton
        Date Coded: August 17, 2011
        ScriptName is used to register events for this script
        LogName is used to determine which classic log to write to
        
        Microsoft .NET Framework 3.5 or greater is required.
        
        This script was modified to pull the record id directly from the
        event subsystem to work around an issue that is potentially caused
        from pulling in all event id's.
    .LINK
        https://code.google.com/p/mod-posh/wiki/New-PrintJob
    .LINK
        http://www.patton-tech.com/2012/04/updated-new-printjob-script.html
#>
Param
    (
    $FileName = "PrintLog-$((get-date -format "yyyMMdd")).csv",
    $FilePath = "P:\PrintLogs",
    $eventRecordID,
    $eventChannel,
    $SqlUser ,
    $SqlPass ,
    $SqlServer = 'SQL',
    $SqlDatabase = 'Printing',
    $SqlTable = 'JobLog',
    $Logged = $True,
    $Email = $True
    )
Begin
    {
        $ScriptName = $MyInvocation.MyCommand.ToString()
        $ScriptPath = $MyInvocation.MyCommand.Path
        $Username = $env:USERDOMAIN + "\" + $env:USERNAME
        $ErrorActionPreference = "Stop"
        
        New-EventLog -Source $ScriptName -LogName 'Windows Powershell' -ErrorAction SilentlyContinue

        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nStarted: " + (Get-Date).toString()
        Write-EventLog -LogName 'Windows Powershell' -Source $ScriptName -EventID "100" -EntryType "Information" -Message $Message 

        #	Dotsource in the functions you need.
        $From = 'printserver@company.com'
        $To = 'administrator@company.com'
        $SMTPServer = 'smtp.company.com'
        }
Process
    {
        Try
        {
            $Event307 = Get-WinEvent -ErrorAction Stop -LogName $eventChannel -FilterXPath "<QueryList><Query Id='0' Path='$eventChannel'><Select Path='$eventChannel'>*[System[(EventRecordID=$eventRecordID)]]</Select></Query></QueryList>"
            $PaperSize = Get-WmiObject -Class Win32_PrintJob -Filter "JobId=$Event307XML.Event.UserData.DocumentPrinted.Param1"
            $Event307XML = ([xml]$Event307.ToXml())
            }
        Catch
        {
            $Message = $Error[0]
            Write-Warning $Message
            Write-EventLog -LogName 'Windows Powershell' -Source $ScriptName -EventID "101" -EntryType "Error" -Message $Message 
            Break
            }
            

        $Client = $Event307.Properties[3].Value
        if($Client.IndexOf("\\") -gt -1)
        {
            $Lookup = "nslookup $($Client.Substring(2,($Client.Length)-2)) |Select-String 'Name:'"
            }
        else
        {
            $Lookup = "nslookup $($Client) |Select-String 'Name:'"
            }
        
        Try
        {
            [string]$Return = Invoke-Expression $Lookup
            $Client = $Return.Substring($Return.IndexOf(" "),(($Return.Length) - $Return.IndexOf(" "))).Trim()
            }
        Catch
        {
            $Client = $PrintJob.Properties[3].Value
            }
        if ((Test-Path -Path "$($FilePath)\$($Event307XML.Event.UserData.DocumentPrinted.Param1).xml") -eq $true)
        {
            $Copies = (Import-Clixml "$($FilePath)\$($Event307XML.Event.UserData.DocumentPrinted.Param1).xml").Copies
            Remove-Item "$($FilePath)\$($Event307XML.Event.UserData.DocumentPrinted.Param1).xml"
            }
        else
        {
            $Copies = 1
            }
            
        $PrintLog = New-Object -TypeName PSObject -Property @{
            Time = $Event307.TimeCreated
            Job = $Event307XML.Event.UserData.DocumentPrinted.Param1
            Document = $Event307XML.Event.UserData.DocumentPrinted.Param2
            User = $Event307XML.Event.UserData.DocumentPrinted.Param3
            Client = $Client
            Printer = $Event307XML.Event.UserData.DocumentPrinted.Param6
            Port = $Event307XML.Event.UserData.DocumentPrinted.Param5
            Size = $Event307XML.Event.UserData.DocumentPrinted.Param7
            Pages = $Event307XML.Event.UserData.DocumentPrinted.Param8
            Copies = $Copies
            PaperSize = $PaperSize
            }
        $DocumentName = ($PrintLog.Document).Replace("'","``")
        $Size = $PrintLog.Size
        try
        {
            $ErrorActionPreference = 'Stop'
            $SqlConn = New-Object System.Data.SqlClient.SqlConnection("Server=$($SqlServer);Database=$($SqlDatabase);Uid=$($SqlUser);Pwd=$($SqlPass)")
            $SqlConn.Open()
            $Sqlcmd = $SqlConn.CreateCommand()
            $Sqlcmd.CommandText = "INSERT INTO [dbo].[$($SqlTable)] ([Time],[UserName],[Pages],[DocumentName],[Client],[Size],[Printer],[Port],[Job],[Copies],[PaperSize]) `
                VALUES ('$($PrintLog.Time)','$($PrintLog.User)',$([int]$PrintLog.Pages),'$($DocumentName)','$($PrintLog.Client)',$Size,'$($PrintLog.Printer)','$($PrintLog.Port)',$([int]$PrintLog.Job),$([int]$PrintLog.Copies).$([int]$PrintLog.PaperSize))"
            $Sqlcmd.ExecuteNonQuery() |Out-Null
            $SqlConn.Close()
            }
        catch
        {
            $SqlConn.Close()
            $MyError = New-Object -TypeName PSObject -Property @{
                SQLStatement = $Sqlcmd.CommandText
                ErrorDate = Get-Date
                Error = $Error[0].exception.message.tostring()
                Data = $PrintLog
                }
            $SqlConn.Close()
            $ErrorLog = ConvertTo-Csv -InputObject $MyError -NoTypeInformation
            $ErrorLog |Select-Object -Skip 1 |Out-File -FilePath "$($FilePath)\ErrorLog.csv" -Append
            
            if ($Email -eq $true)
            {
                $BodyHtml = $MyError |ConvertTo-Html
                [string]$Body = $BodyHtml
                Send-MailMessage -BodyAsHtml $Body -From $From -SmtpServer $SMTPServer -Subject $Error[0].exception.message.tostring() -To $To
                }
            }
        }
End
    {
        if ($Logged -eq $true)
        {
            $PrintLog = $PrintLog |Select-Object -Property Size, Time, User, Job, Client, Port, Printer, Pages, Document, Copies, PaperSize
            $PrintLog = ConvertTo-Csv -InputObject $PrintLog -NoTypeInformation

            if ((Test-Path -Path "$($FilePath)\$($FileName)") -eq $true)
            {
                $PrintLog |Select-Object -Skip 1 |Out-File -FilePath "$($FilePath)\$($FileName)" -Append
                }
            else
            {
                $PrintLog |Out-File -FilePath "$($FilePath)\$($FileName)"
                }
            }
        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nFinished: " + (Get-Date).toString()
        Write-EventLog -LogName 'Windows Powershell' -Source $ScriptName -EventID "100" -EntryType "Information" -Message $Message
        }
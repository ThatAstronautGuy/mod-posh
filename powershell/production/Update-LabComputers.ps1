<#
    .SYNOPSIS
        Update lab computers
    .DESCRIPTION
        This script updates the Administrators group on the lab computers. This could be done
        with a GPO, but sometimes our requirements change and this is easier and more immediate.
    .PARAMETER ADSPath
        A valid LDAP URI to the OU containing the computers to update.
    .PARAMETER GroupName
        The name of the group to add to Administrators.
    .PARAMETER DomainName
        The NetBIOS domain name of your domain.
    .EXAMPLE
        Update-LabComputers -ADSPath "LDAP://OU=Workstations,DC=company,DC=com" -GroupName "StudentAdmins" -DomainName "COMPANY"
        
        Description
        -----------
        The basic syntax of the script.
    .EXAMPLE
	    Update-LabComputers -ADSPath "LDAP://OU=Workstations,DC=company,DC=com" -GroupName "StudentAdmins" -DomainName "COMPANY" | Export-Csv ./Report.csv -NoTypeInformation
		
		Description
		-----------
		Shows piping the output of the script to a csv file.
    .NOTES
        ScriptName: Update-LabComputers
        Created By: Jeff Patton
        Date Coded: May 24, 2011
        ScriptName is used to register events for this script
        LogName is used to determine which classic log to write to
    .LINK
        https://code.google.com/p/mod-posh/wiki/Update-LabComputers
#>
Param
    (
        [Parameter(Mandatory=$true)]
        [String]$ADSPath,
        [Parameter(Mandatory=$true)]
        [String]$GroupName,
        [Parameter(Mandatory=$true)]
        [String]$DomainName
    )
Begin
    {
        $ScriptName = $MyInvocation.MyCommand.ToString()
        $LogName = "Application"
        $ScriptPath = $MyInvocation.MyCommand.Path
        $Username = $env:USERDOMAIN + "\" + $env:USERNAME

        New-EventLog -Source $ScriptName -LogName $LogName -ErrorAction SilentlyContinue

        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nStarted: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "100" -EntryType "Information" -Message $Message 

        #	Dotsource in the functions you need.
        Try
        {
            Import-Module .\includes\ActiveDirectoryManagement.psm1
            }
        Catch
        {
            Write-Warning "Must have the ActiveDirectoryManagement Module available."
            Write-EventLog -LogName $LogName -Source $ScriptName -EventID "101" -EntryType "Error" -Message "ActiveDirectoryManagement Module Not Found"
            Break
            }
        $LabComputers = Get-ADObjects -ADSPath $ADSPath
		$Jobs = @()
    }
Process
    {
        foreach ($LabComputer in $LabComputers)
        {
            $Status = Add-DomainGroupToLocalGroup -ComputerName $LabComputer.Properties.name -DomainGroup $GroupName -UserDomain $DomainName
			
			$ThisJob = New-Object PSObject -Property @{
				ComputerName = $($LabComputer.Properties.name)
				Status = [string]$Status
				}
            $Jobs += $ThisJob
        }
    }
End
    {
        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nFinished: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "100" -EntryType "Information" -Message $Message
		
		Return $Jobs
    }

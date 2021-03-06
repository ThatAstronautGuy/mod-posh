Function Reset-ComputerAccount
{
    <#
        .SYNOPSIS
            Reset computer account password
        .DESCRIPTION
            This function will reset the computer account password for a single computer
            or for an OU of computers.
        .PARAMETER ADSPath
            The ADSPath of the computer account, or containing OU.
        .EXAMPLE
            Reset-ComputerAccount -ADSPath "LDAP://CN=Desktop-PC01,OU=Workstations,DC=company,DC=com"
            
            Description
            -----------
            Example usage showing single computer account reset.
        .NOTES
        .LINK
            http://scripts.patton-tech.com/wiki/PowerShell/ActiveDirectoryManagement#Reset-ComputerAccount
    #>
    
    Param
    (
        [Parameter(Mandatory=$true)]
        [String]$ADSPath
    )
    
    Begin
    {
        $Computer = [ADSI]$ADSPath
    }
    
    Process
    {
        $Computer.SetPassword($($Computer.name)+"$")
    }
    
    End
    {
    }
}
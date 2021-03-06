Function Get-UpTime
{
    <#
        .SYNOPSIS
            Get uptime of one or more computers
        .DESCRIPTION
            This script uses Win32_ComputerSystem to determine how long your system has been running.
        .PARAMETER ComputerName
            One or more computer names
        .EXAMPLE
            Get-UpTime -ComputerName ".", "server01" |Sort-Object -Property Days -Descending

            ComputerName Days Hours Minutes
            ------------ ---- ----- -------
            server01       39    18      25
            Desktop01       0     1      38

            Description
            -----------
            This example shows using the function with an array of computer names, and sorting the output
            descending order by days.
        .EXAMPLE
            $Servers | foreach {Get-UpTime $_.Properties.name} |Sort-Object -Property Days -Descending

            ComputerName    Days Hours Minutes
            ------------    ---- ----- -------
            server01         144    22      58
            server02         144    22      16
            server03         144    23       9
            server04         139    22      42

            Description
            -----------
            This example shows passing in computer computer names from an object.
        .NOTES
            FunctionName : Get-UpTime
            Created by   : jspatton
            Date Coded   : 10/19/2011 11:22:34
        .LINK
            http://scripts.patton-tech.com/wiki/PowerShell/Untitled1#Get-UpTime
        .LINK
            http://msdn.microsoft.com/en-us/library/aa394591(VS.85).aspx  
    #>
    [CmdletBinding()]
    Param
        (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $ComputerName = "."
        )
    Begin
    {       
        $Report = @()
        }
    Process
    {
        foreach ($Computer in $ComputerName) 
        {
            if ($Computer -eq ".")
            {
                Write-Verbose "Change the dot to a hostname"
                $Computer = (& hostname)
                }
            Write-Verbose "Make sure that $($Computer) is online with a single ping."
            Test-Connection -ComputerName $Computer -Count 1 -ErrorAction SilentlyContinue |Out-Null
            
            if ($?)
            {
                Write-Verbose "Try to connect to $($Computer) fail silently."
                try
                {
                    Write-Verbose "Convert the WMI value for LastBootUpTime into a date, and subtract it from now to get uptime"
                    $Uptime = (Get-Date) - ([System.Management.ManagementDateTimeconverter]::ToDateTime((Get-WMIObject -class Win32_OperatingSystem -ComputerName $Computer).LastBootUpTime))
                    $ComputerUpTime = New-Object -TypeName PSObject -Property @{
                        ComputerName = $Computer
                        Days = $Uptime.Days
                        Hours = $Uptime.Hours
                        Minutes = $uptime.Minutes
                        }
                    $Report += $ComputerUpTime
                    }
                catch
                {
                    Write-Verbose $Error[0].Exception
                    }
                }
            else
            {
                Write-Verbose "Unable to connect to $($Computer)"
                }
            }
        }
    End
    {
        Return $Report
        }
    }
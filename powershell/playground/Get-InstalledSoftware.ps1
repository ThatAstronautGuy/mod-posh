Function Get-InstalledSoftware
{
    <#
        .SYNOPSIS
            Return a list of software that appears in Add/Remove
        .DESCRIPTION
            This function returns a list of software that appears in the Add/Remove applet in the Control Panel.
        .EXAMPLES
        .NOTES
            This works for x86 software, this does not appear to work with x64 software at the moment.
        .LINK
    #>
    
    Param
    (
    )
    Begin
    {
        $Keys = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
        $Items = $Keys |ForEach-Object {Get-ItemProperty $_.PsPath}
        $InstalledSoftware = @()
        }

    Process
    {
        ForEach ($Item in $Items)
        {
            $ThisSoftware = New-Object -TypeName PSObject -Property @{
                DisplayName = $Item.DisplayName
                DisplayVerison = $Item.DisplayVersion
                Publisher = $Item.Publisher
                InstallDate = $Item.InstallDate
                HelpLink = $Item.HelpLink
                UninstallString = $Item.UninstallString
                }
            $InstalledSoftware += $ThisSoftware
            }
        }

    End
    {
        Return $InstalledSoftware
        }
}
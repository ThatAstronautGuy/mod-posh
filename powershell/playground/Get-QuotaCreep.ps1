$Files = Get-ChildItem -Filter *.html
$Return = @()
$FileCount = 1
foreach ($File in $Files)
{
    $ie = New-Object -ComObject InternetExplorer.Application
    $ie.Navigate("file:///C:/Reports/Quota/$($File.Name)")
    $Data = $ie.Document.getElementsByTagName("TD") |Select-Object -Property innerText
    $RecordFlag = $false
    $Headers = @()
    $Report = @()
    foreach ($Datum in $Data)
    {
        if ($Datum.innerText -eq "Report statistics")
        {
            $RecordFlag = $true
            }
        if ($RecordFlag -eq $true)
        {
            if (!($Datum.innerText -eq "Report statistics"))
            {
                switch ($Datum.innerText)
                {
                    "Folder"
                    {
                        $Headers += $Datum.innerText
                        }
                    "Owner"
                    {
                        $Headers += $Datum.innerText
                        }
                    "Quota"
                    {
                        $Headers += $Datum.innerText
                        }
                    "Usage"
                    {
                        $Headers += $Datum.innerText
                        }
                    "Used"
                    {
                        $Headers += $Datum.innerText
                        }
                    "Peak Usage"
                    {
                        $Headers += $Datum.innerText
                        }
                    "Peak Usage Time"
                    {
                        $Headers += $Datum.innerText
                        }
                    Default
                    {
                        $Report += $Datum.innerText
                        }
                    }
                }
            }
        }

    for ($Counter = 0; $Counter -le ($Report.Count-$Headers.Count); $Counter = $Counter + $Headers.Count)
    {
        $NewData = New-Object -TypeName PSObject -Property @{
            $($Headers[0]) = "$($Report[$Counter+0])"
            $($Headers[1]) = "$($Report[$Counter+1])"
            $($Headers[2]) = "$($Report[$Counter+2])"
            $($Headers[3]) = "$($Report[$Counter+3])"
            $($Headers[4]) = "$($Report[$Counter+4])"
            $($Headers[5]) = "$($Report[$Counter+5])"
            $($Headers[6]) = "$($Report[$Counter+6])"
            DataCollected = $File.LastWriteTime
            }
            $Return += $NewData
        }
    $ie.Quit()
    Write-Host "File $($FileCount) of $($Files.Count)"
    $FileCount ++
    }
    Remove-Variable ie
    get-date
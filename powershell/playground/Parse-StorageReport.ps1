Get-Date
$CsvReport = @()
$FileReports = Get-ChildItem C:\StorageReports\node1\Scheduled\FilesbyOwner*.csv
foreach ($File in $FileReports)
{
    $Report = Get-Content -Path $file.FullName
    if (($Report |Select-String "Report Folders: ,`"U:") -ne $null)
    {
        $SkipFile = $true
        Write-Verbose "Skipping file with old drives"
        }
    if ($SkipFile -ne $true)
    {
        Write-Verbose "Parsing file, $($file.fullname)"
        $SizeByOwner = $false
        foreach ($line in $Report)
        {
            if ($line -eq "Size by Owner")
            {
                $SizeByOwner = $true
                }
            if ($line -eq "")
            {
                $SizeByOwner = $false
                }
            if ($SizeByOwner -eq $true)
            {
                if ($line -ne "Size by Owner")
                {
                    $Array = ($line.Replace("`"","")).Split(",")
                    $Owner = $Array[0]
                    $TimeStamp = $file.LastWriteTime
                    if ($Array[1].IndexOfAny("MB") -gt 1)
                    {
                        $FileSize = $Array[1]
                        $FileCount = $Array[2]
                        }
                    else
                    {
                        $FileSize = $Array[2]
                        $FileCount = $Array[1]
                        }
                    $line = New-Object -TypeName PSObject -Property @{
                        Owner = $Owner
                        Size = $FileSize
                        Files = $FileCount
                        Time = $TimeStamp
                        }
                    $CsvReport += $line
                    }
                }
            }
        $SkipFile = $false
        }
    }
Get-Date
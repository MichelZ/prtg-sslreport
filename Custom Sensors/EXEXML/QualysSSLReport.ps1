<#
.SYNOPSIS

Retrieves a Qualys SSL Report and outputs the data as JSON that PRTG understands (Advanced Custom Script Sensor)

.DESCRIPTION

The QualysSSLReport.ps1 script retrieves data using Get-SSLReport.psm1.
It converts the data to something that PRTG understands.

.PARAMETER ServerName
The server name to scan. Should be an FQDN.
Note: The server needs to be publicly accessible to the Qualys Service. It does not work for internal services.

.PARAMETER MaxCacheAgeHours
The maximum age that we accept cached content. Set to 0 to disable caching.

.PARAMETER TimeoutSeconds
The timeout in seconds. This is only for the actual Invoke-WebRequest, and not for the script itself.
The script can run longer than this.

.INPUTS

None. You cannot pipe objects to QualysSSLReport.ps1.

.OUTPUTS

System.String. A JSON string that PRTG can understand as a custom sensor

.NOTES
2019-11-22  Version 0.1   Initial Version
2022-06-07  Version 0.1.2 Updated error handling

.EXAMPLE

PS> .\QualysSSLReport.ps1 -ServerName microsoft.com
{
    "prtg":  [
                {
                    "channel":  "40.76.4.15",
                    "value":  3,
                    "warning":  "0",
                    "notifychanged":  "1"
                },
                {
                    "channel":  "40.113.200.201",
                    "value":  3,
                    "warning":  "0",
                    "notifychanged":  "1"
                },
                {
                    "channel":  "104.215.148.63",
                    "value":  3,
                    "warning":  "0",
                    "notifychanged":  "1"
                },
                {
                    "channel":  "40.112.72.205",
                    "value":  3,
                    "warning":  "0",
                    "notifychanged":  "1"
                },
                {
                    "channel":  "13.77.161.179",
                    "value":  3,
                    "warning":  "0",
                    "notifychanged":  "1"
                }
            ]
}

.LINK

https://github.com/MichelZ/prtg-sslreport
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerName,
    [int]$MaxCacheAgeHours = 8,
    [int]$TimeoutSeconds = 600
)

Import-Module $PSScriptRoot\Get-SSLReport.psm1

function Get-SSLGradeValue {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Grade
    )

    switch ($Grade)
    {
        "A+" { return 0; }
        "A" { return 1; }
        "A-" { return 2; }
        "B" { return 3; }
        "C" { return 4; }
        "D" { return 5; }
        "E" { return 6; }
        "F" { return 7; }
        "T" { return 8; }
        "M" { return 9; }
        default { throw; }
    }
}

try {
    $result = Get-SSLReport -ServerName $ServerName -TimeoutSeconds $TimeoutSeconds -MaxCacheAgeHours $MaxCacheAgeHours
} catch {
    $r = $_.Exception

    $errorobject = [pscustomobject]@{
        'error'='1';
        'text'=$r;
    }

    $prtg = [pscustomobject]@{
        prtg = $errorobject
    }

    Write-Host ($prtg | ConvertTo-Json);
    return
}

$parsed = $result | ConvertFrom-Json

# Calculate the lowest grade for the overall grade
$lowestGrade = $parsed.endpoints | foreach-object { $_ | Add-Member -MemberType NoteProperty -Name 'GradeValue' -Value (Get-SSLGradeValue -Grade $_.grade) -PassThru } | measure-object -Property GradeValue -Maximum

# Construct PRTG Sensor Output Result
$prtg = @()

$prtg += [pscustomobject]@{
    'channel'='Overall Grade';
    'value'=$lowestGrade.Maximum;
    'warning'='0';
    'notifychanged'='1';
    'valuelookup'='michelz.lookup.qualys.grade'
}

foreach ($endpoint in $parsed.endpoints)
{
    $prtg += [pscustomobject]@{
        'channel'=$endpoint.ipAddress;
        'value'=(Get-SSLGradeValue -Grade $endpoint.grade);
        'warning'='0';
        'notifychanged'='1';
        'valuelookup'='michelz.lookup.qualys.grade';
    }
}

$result = [pscustomobject]@{
    result = $prtg
}

$jsonDoc = [pscustomobject]@{
    prtg = $result
}

Write-Host ($jsonDoc | ConvertTo-Json -Depth 5)
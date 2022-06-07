<#
.SYNOPSIS

Retrieve an SSL Report from the Qualys SSL Tester

.DESCRIPTION

This PowerShell Script README: https://github.com/MichelZ/prtg-sslreport/blob/master/README.md
SSL Tester: https://www.ssllabs.com/ssltest
SSL Tester API: https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md

The script waits when a scan is in progress

Note: Only Port 443 (HTTPS) is supported by Qualys.

.PARAMETER ServerName
The server name to scan. Should be an FQDN.
Note: The server needs to be publicly accessible to the Qualys Service. It does not work for internal services.

.PARAMETER MaxCacheAgeHours
The maximum age that we accept cached content. Set to 0 to disable caching.

.PARAMETER TimeoutSeconds
The timeout in seconds. This is only for the actual Invoke-WebRequest, and not for the script itself.
The script can run longer than this.

.INPUTS

None. You cannot pipe objects to Get-SSLReport

.OUTPUTS

System.String. Get-SSLReport returns a JSON string with information about the Test Results for the ServerName specified
For details, see here: https://github.com/ssllabs/ssllabs-scan/blob/master/ssllabs-api-docs-v3.md#host
You can easily parse this using `Get-SSLReport -servername example.com | ConvertTo-Json`

.NOTES
2019-11-22  Version 0.1   Initial Version
2021-03-19  Version 0.1.1 Updated input from "host" to match parameter name of function "ServerName"
2022-06-07  Version 0.1.2 Updated error handling

.EXAMPLE

PS> Get-SSLReport -servername "microsoft.com"
{
  "host": "microsoft.com",
  "port": 443,
  "protocol": "http",
  "isPublic": true,
  "status": "READY",
  "startTime": 1574401124504,
  "testTime": 1574401672845,
  "engineVersion": "1.36.3",
  "criteriaVersion": "2009q",
  "endpoints": [
    {
      "ipAddress": "40.76.4.15",
      "statusMessage": "Ready",
      "grade": "B",
      "gradeTrustIgnored": "B",
      "hasWarnings": true,
      "isExceptional": false,
      "progress": 100,
      "duration": 109470,
      "delegation": 1
    },
    {
      "ipAddress": "40.113.200.201",
      "statusMessage": "Ready",
      "grade": "B",
      "gradeTrustIgnored": "B",
      "hasWarnings": true,
      "isExceptional": false,
      "progress": 100,
      "duration": 98284,
      "delegation": 1
    },
    {
      "ipAddress": "104.215.148.63",
      "statusMessage": "Ready",
      "grade": "B",
      "gradeTrustIgnored": "B",
      "hasWarnings": true,
      "isExceptional": false,
      "progress": 100,
      "duration": 130120,
      "delegation": 1
    },
    {
      "ipAddress": "40.112.72.205",
      "statusMessage": "Ready",
      "grade": "B",
      "gradeTrustIgnored": "B",
      "hasWarnings": true,
      "isExceptional": false,
      "progress": 100,
      "duration": 121456,
      "delegation": 1
    },
    {
      "ipAddress": "13.77.161.179",
      "statusMessage": "Ready",
      "grade": "B",
      "gradeTrustIgnored": "B",
      "hasWarnings": true,
      "isExceptional": false,
      "progress": 100,
      "duration": 88946,
      "delegation": 1
    }
  ]
}

.LINK

https://github.com/MichelZ/prtg-sslreport
#>
function Get-SSLReport {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerName,
        [int]$MaxCacheAgeHours = 8,
        [int]$TimeoutSeconds = 600
    )

    # Construct the URI part for Caching
    if ($MaxCacheAgeHours -eq 0) {
        $MaxCacheAgeHours -eq 1
        $cacheString = "&startNew=on"
    } elseif ($MaxCacheAgeHours -lt 0) {
        $cacheString = ""
    } else {
        $cacheString = "&fromCache=on&maxAge=$MaxCacheAgeHours"
    }

    # Enforce TLS 1.2 use for compatibility
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

    try {
      $result = Invoke-WebRequest -UseBasicParsing -Uri "https://api.ssllabs.com/api/v3/analyze?host=$ServerName$cacheString" -TimeoutSec $TimeoutSeconds -Method Get
    } catch [System.Net.WebException] {
      $r = $_.Exception
      switch ($r.Response.StatusCode)
      {
        200 { }
        429 { throw "STATUS: $($r.Response.StatusCode) ERROR: throttled." }
        500 { throw "STATUS: $($r.Response.StatusCode) ERROR: internal error. $($r.Response.Content)"}
        503 { throw "STATUS: $($r.Response.StatusCode) ERROR: the service is not available."}
        529 { throw "STATUS: $($r.Response.StatusCode) ERROR: the service is overloaded."}
        default { throw "STATUS: $($r.Response.StatusCode) ERROR: $($r.Response.Content)" }
      }
  }

    $parsed = $result.Content | ConvertFrom-Json
    
    switch ($parsed.status)
    {
        "IN_PROGRESS" { 
          Write-Verbose "Scan is in progress. Waiting."
          start-sleep -Seconds 10; return Get-SSLReport -serverName $serverName -maxCacheAge -1 -timeoutSec $timeoutSec }
        "DNS" { 
          Write-Verbose "Scan is in progress. Waiting."
          start-sleep -Seconds 10; return Get-SSLReport -serverName $serverName -maxCacheAge -1 -timeoutSec $timeoutSec }
        "ERROR" { 
            throw $parsed.statusMessage
        }
        "READY" {
            return $result.Content
        }
        default { throw }
    }
}

Export-ModuleMember Get-SSLReport

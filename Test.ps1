
function Convert-IPv4ToNumber {
    param([string]$Address)

    $b = [Net.IPAddress]::Parse($Address).GetAddressBytes()
    if ($b.Length -ne 4) { throw "Invalid IPv4 address" }

    return ([long]$b[0] * 16777216) +
           ([long]$b[1] * 65536) +
           ([long]$b[2] * 256) +
           [long]$b[3]
}

function Test-BuildSegment {
    param(
        [string]$IPAddress,
        [string]$JsonPath
    )

    try {
        $json = Get-Content -LiteralPath $JsonPath -Raw -ErrorAction Stop |
            ConvertFrom-Json -ErrorAction Stop

        if (-not $json.Boundaries) {
            throw "JSON contains no boundaries"
        }

        $device = Convert-IPv4ToNumber $IPAddress
        $count = 0

        foreach ($boundary in $json.Boundaries) {
            if ($boundary.BoundaryType -ne 3) { continue }

            $range = @($boundary.Value -split '\s*-\s*')
            if ($range.Count -ne 2) { throw "Invalid IP range" }

            $start = Convert-IPv4ToNumber $range[0]
            $end = Convert-IPv4ToNumber $range[1]

            if ($start -gt $end) { throw "Invalid range order" }

            $count++

            if ($device -ge $start -and $device -le $end) {
                return [PSCustomObject]@{
                    Status = 'Approved'
                    Detail = $boundary.DisplayName
                }
            }
        }

        if ($count -eq 0) { throw "No valid build ranges found" }

        return [PSCustomObject]@{
            Status = 'Denied'
            Detail = 'No matching build segment'
        }
    }
    catch {
        return [PSCustomObject]@{
            Status = 'Unavailable'
            Detail = $_.Exception.Message
        }
    }
}

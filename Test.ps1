
# Get the device's actual IPv4 subnet mask
$ipInfo = [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
    ForEach-Object { $_.GetIPProperties().UnicastAddresses } |
    Where-Object { $_.Address.ToString() -eq $IPAddress } |
    Select-Object -First 1

foreach ($boundary in $json.Boundaries)
{
    $matched = $false

    switch ([int]$boundary.BoundaryType)
    {
        0 {
            # IP subnet
            $parts = ([string]$boundary.Value).Split('/')
            $network = Convert-IPv4ToNumber $parts[0]

            if ($parts.Count -eq 2) {
                $prefix = [int]$parts[1]
                if ($prefix -lt 0 -or $prefix -gt 32) {
                    throw "Invalid subnet prefix: $($boundary.Value)"
                }

                $mask = if ($prefix -eq 0) { [long]0 } else {
                    ([long]4294967295 -shl (32 - $prefix)) -band [long]4294967295
                }
            }
            else {
                if (-not $ipInfo -or -not $ipInfo.IPv4Mask) {
                    throw "Device subnet mask unavailable"
                }
                $mask = Convert-IPv4ToNumber $ipInfo.IPv4Mask.ToString()
            }

            $matched = (($device -band $mask) -eq ($network -band $mask))
            $count++
        }

        3 {
            # IP address range
            $range = @($boundary.Value -split '\s*-\s*')
            if ($range.Count -ne 2) { throw "Invalid IP range" }

            $start = Convert-IPv4ToNumber $range[0]
            $end = Convert-IPv4ToNumber $range[1]

            if ($start -gt $end) { throw "Invalid range order" }

            $matched = ($device -ge $start -and $device -le $end)
            $count++
        }

        default {
            Write-OSDAuthLog "Boundary type $($boundary.BoundaryType) requires separate validation: $($boundary.DisplayName)"
        }
    }

    if ($matched)
    {
        Write-OSDAuthLog "Build APPROVED | IP: $IPAddress | Segment: $($boundary.DisplayName)"
        return [PSCustomObject]@{
            Status = 'Approved'
            Detail = $boundary.DisplayName
        }
    }
}

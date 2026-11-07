
# Build segment JSON location
$folder = '\\nas01.example.com\OSDContent\BuildSegments'
$deviceIP = $labelIPAddress.Text -replace '^IP:\s*', ''

$result = [PSCustomObject]@{
    Status = 'Unavailable'
    Detail = 'No valid JSON available'
}

try {
    $files = Get-ChildItem -LiteralPath $folder -Filter 'BuildSegments-*.json' -File -ErrorAction Stop |
        Sort-Object Name -Descending |
        Select-Object -First 3

    foreach ($file in $files) {
        Write-OSDAuthLog "Trying JSON: $($file.Name)"

        $result = Test-BuildSegment -IPAddress $deviceIP -JsonPath $file.FullName

        if ($result.Status -ne 'Unavailable') {
            Write-OSDAuthLog "Using JSON: $($file.Name)"
            break
        }
    }
}
catch {
    Write-OSDAuthLog "NAS error: $($_.Exception.Message)"
}

Set-BuildSegmentStatus -Status $result.Status

if ($result.Status -ne 'Approved') {
    return
}

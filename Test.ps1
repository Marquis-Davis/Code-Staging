l
# Validate build segment after successful AD authentication
Set-BuildSegmentStatus -Status 'Checking'
$formAuthentication.Refresh()

$jsonPath = '\\nas01.example.com\OSDContent\ApprovedBuildSegments.json'
$deviceIP = $labelIPAddress.Text -replace '^IP:\s*', ''

$result = Test-BuildSegment -IPAddress $deviceIP -JsonPath $jsonPath

Write-OSDAuthLog "Build result: $($result.Status) | $($result.Detail)"
Set-BuildSegmentStatus -Status $result.Status

if ($result.Status -ne 'Approved') {
    return
}

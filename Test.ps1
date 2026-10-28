
# Approved OSD boundary groups
$buildGroups = @(
    'Example-OSD-Build-Group'
)

$boundaries = foreach ($group in $buildGroups) {
    Get-CMBoundary -BoundaryGroupName $group |
        Select-Object @{Name='Group';Expression={$group}},
                      DisplayName, BoundaryType, Value
}

if (-not $boundaries) {
    throw "No boundaries found. Check the build group names."
}

$policy = @{
    UpdatedUTC = [DateTime]::UtcNow.ToString('o')
    Boundaries = @($boundaries)
}

$path = 'C:\Temp\ApprovedBuildSegments.json'
New-Item -ItemType Directory -Path 'C:\Temp' -Force | Out-Null

$policy | ConvertTo-Json -Depth 4 |
    Set-Content -Path $path -Encoding UTF8

$boundaries | Format-Table -AutoSize
Write-Host "JSON exported: $path"

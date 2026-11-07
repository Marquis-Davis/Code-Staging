# Settings
$SiteCode = 'ABC'
$Provider = 'cm01.example.com'
$Folders = @(
    '\\nas01.example.com\OSD\BuildSegments'
    '\\nas02.example.com\OSD\BuildSegments'
)

$ErrorActionPreference = 'Stop'

# Connect to ConfigMgr
Import-Module "$env:SMS_ADMIN_UI_PATH\..\ConfigurationManager.psd1"

if (-not (Get-PSDrive -Name $SiteCode -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $Provider |
        Out-Null
}

# Read all boundaries
Push-Location "${SiteCode}:\"
try {
    $Boundaries = @(
        Get-CMBoundary |
            Select-Object BoundaryID, DisplayName, BoundaryType, Value
    )
}
finally {
    Pop-Location
}

# Do not publish an empty or incomplete export
if ($Boundaries.Count -eq 0) {
    throw 'No boundaries returned. Existing files were left untouched.'
}

foreach ($Boundary in $Boundaries) {
    if ([string]::IsNullOrWhiteSpace($Boundary.Value)) {
        throw "Boundary $($Boundary.BoundaryID) has no value. Export stopped."
    }
}

# Build the JSON
$Now = [datetime]::UtcNow

$Json = [ordered]@{
    GeneratedUtc  = $Now.ToString('o')
    SiteCode      = $SiteCode
    BoundaryCount = $Boundaries.Count
    Boundaries    = $Boundaries
} | ConvertTo-Json -Depth 5

# Unique filename for this run
$RunId = [guid]::NewGuid().ToString('N')
$FileName = "BuildSegments-$($Now.ToString('yyyyMMdd-HHmmss'))-$RunId.json"
$Failures = @()

# Publish independently to each NAS
foreach ($Folder in $Folders) {
    $FinalFile = Join-Path $Folder $FileName
    $TempFile = "$FinalFile.tmp"

    try {
        # Write a separate temporary file
        [System.IO.File]::WriteAllText($TempFile, $Json)

        # Read it back and verify before publishing
        $SavedJson = [System.IO.File]::ReadAllText($TempFile)

        if ($SavedJson -cne $Json) {
            throw 'Written file does not match the export.'
        }

        $Check = $SavedJson | ConvertFrom-Json
        if (@($Check.Boundaries).Count -ne $Boundaries.Count) {
            throw 'Boundary count validation failed.'
        }

        # Publish by renaming in the same folder
        [System.IO.File]::Move($TempFile, $FinalFile)

        Write-Output "Published $($Boundaries.Count) boundaries: $FinalFile"
    }
    catch {
        $Failures += "${Folder}: $($_.Exception.Message)"
    }
}

if ($Failures.Count -gt 0) {
    throw ($Failures -join "`r`n")
}
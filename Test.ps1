l
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

# Configuration
$TenantId = "YOUR-TENANT-ID"
$ClientId = "YOUR-CLIENT-ID"
$SiteId = "YOUR-SHAREPOINT-SITE-ID"
$ListId = "YOUR-SHAREPOINT-LIST-ID"
$DriverColumn = "DriverPath" # SharePoint internal column name

$BootImagePath = "C:\OSD\BootImage\boot.wim"
$MountLocation = "C:\OSD\Mount"
$LogFolder = "C:\OSD\Logs"

$LogFile = Join-Path $LogFolder "DriverInjection.log"
$MissingFile = Join-Path $LogFolder "MissingDrivers.log"

# Create directories
foreach ($Path in @($MountLocation, $LogFolder)) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-Log {
    param([string]$Message)

    $Entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
    Write-Host $Entry
    Add-Content -Path $LogFile -Value $Entry
}

function Get-SharePointAccessToken {
    $Secret = $env:OSD_BOOTIMAGE_CLIENT_SECRET

    if ([string]::IsNullOrWhiteSpace($Secret)) {
        throw "Environment variable OSD_BOOTIMAGE_CLIENT_SECRET is not set."
    }

    $Body = @{
        client_id     = $ClientId
        client_secret = $Secret
        scope         = "https://graph.microsoft.com/.default"
        grant_type    = "client_credentials"
    }

    $Response = Invoke-RestMethod `
        -Method Post `
        -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
        -Body $Body `
        -ContentType "application/x-www-form-urlencoded" `
        -ErrorAction Stop

    if (-not $Response.access_token) {
        throw "Microsoft Graph did not return an access token."
    }

    return $Response.access_token
}

$SuccessCount = 0
$FailedCount = 0
$MissingCount = 0
$Mounted = $false

try {
    # Authenticate
    $AccessToken = Get-SharePointAccessToken
    Write-Log "Microsoft Graph authentication successful."

    $Headers = @{
        Authorization = "Bearer $AccessToken"
    }

    # Retrieve SharePoint driver paths
    $Uri = "https://graph.microsoft.com/v1.0/sites/$SiteId/lists/$ListId/items?`$expand=fields"

    $Items = @()

    do {
        $Result = Invoke-RestMethod `
            -Method Get `
            -Uri $Uri `
            -Headers $Headers `
            -ErrorAction Stop

        $Items += $Result.value
        $Uri = $Result.'@odata.nextLink'

    } while ($Uri)

    $DriverPaths = @(
        $Items | ForEach-Object {
            $_.fields.$DriverColumn
        } | Where-Object {
            -not [string]::IsNullOrWhiteSpace($_)
        } | Sort-Object -Unique
    )

    Write-Log "Retrieved $($DriverPaths.Count) driver paths from SharePoint."

    if ($DriverPaths.Count -eq 0) {
        throw "No driver paths retrieved. Stopping before DISM."
    }

    # Validate driver paths
    $ValidPaths = @()

    foreach ($DriverPath in $DriverPaths) {
        if (Test-Path -LiteralPath $DriverPath -PathType Container) {
            $ValidPaths += $DriverPath
        }
        else {
            $MissingCount++
            Write-Log "SKIPPED - Missing driver path: $DriverPath"
            Add-Content -Path $MissingFile -Value "MISSING: $DriverPath"
        }
    }

    if ($ValidPaths.Count -eq 0) {
        throw "No valid driver paths found. Stopping before DISM."
    }

    # Validate boot image
    if (-not (Test-Path -LiteralPath $BootImagePath -PathType Leaf)) {
        throw "Boot image not found: $BootImagePath"
    }

    if (@(Get-ChildItem -LiteralPath $MountLocation -Force).Count -gt 0) {
        throw "Mount directory is not empty: $MountLocation"
    }

    # Mount boot image
    Write-Log "Mounting boot image."

    & dism.exe /Mount-Image "/ImageFile:$BootImagePath" /Index:1 "/MountDir:$MountLocation"

    if ($LASTEXITCODE -ne 0) {
        throw "DISM mount failed. Exit code: $LASTEXITCODE"
    }

    $Mounted = $true

    # Inject drivers
    foreach ($DriverPath in $ValidPaths) {
        Write-Log "Injecting: $DriverPath"

        try {
            & dism.exe "/Image:$MountLocation" /Add-Driver "/Driver:$DriverPath" /Recurse

            if ($LASTEXITCODE -ne 0) {
                throw "DISM exit code: $LASTEXITCODE"
            }

            $SuccessCount++
            Write-Log "SUCCESS: $DriverPath"
        }
        catch {
            $FailedCount++
            $Message = $_.Exception.Message

            Write-Log "FAILED: $DriverPath - $Message"
            Add-Content -Path $MissingFile -Value "FAILED: $DriverPath - $Message"

            continue
        }
    }

    # Commit changes
    Write-Log "Committing boot image."

    & dism.exe /Unmount-Image "/MountDir:$MountLocation" /Commit

    if ($LASTEXITCODE -ne 0) {
        throw "DISM commit failed. Exit code: $LASTEXITCODE"
    }

    $Mounted = $false

    # Final summary
    Write-Log "--------------------------------"
    Write-Log "Driver injection completed."
    Write-Log "Successful: $SuccessCount"
    Write-Log "Failed: $FailedCount"
    Write-Log "Missing: $MissingCount"
    Write-Log "Total paths: $($DriverPaths.Count)"
    Write-Log "--------------------------------"
}
catch {
    Write-Log "FATAL ERROR: $($_.Exception.Message)"

    if ($Mounted) {
        Write-Log "Image may still be mounted at $MountLocation. Check DISM mount status."
    }

    throw
}
finally {
    Remove-Variable AccessToken, Headers -ErrorAction SilentlyContinue
}

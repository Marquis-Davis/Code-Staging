$ErrorActionPreference = 'Stop'

$ts = New-Object -ComObject Microsoft.SMS.TSEnvironment

# Verify Capture Image already sets this to the offline Windows folder
$WindowsRoot = $ts.Value('OSDTargetSystemRoot')

if ([string]::IsNullOrWhiteSpace($WindowsRoot)) {
    throw 'OSDTargetSystemRoot is not set.'
}

$SoftwareHive = Join-Path $WindowsRoot 'System32\Config\SOFTWARE'
$HiveName = 'CaptureSoftware'

# Load the offline Windows SOFTWARE registry hive
reg.exe load "HKLM\$HiveName" "$SoftwareHive" | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw 'Unable to load the offline SOFTWARE hive.'
}

try {
    # Replace Contoso with your actual registry key locally
    $RegistryPath = "Registry::HKEY_LOCAL_MACHINE\$HiveName\Contoso\OSD"

    $ImageRelease = Get-ItemPropertyValue `
        -Path $RegistryPath `
        -Name 'ImageRelease'

    if ([string]::IsNullOrWhiteSpace($ImageRelease)) {
        throw 'ImageRelease was empty.'
    }

    # Put it back into the Capture TS environment
    $ts.Value('ImageRelease') = $ImageRelease

    Write-Host "ImageRelease successfully restored to the task sequence."
}
finally {
    reg.exe unload "HKLM\$HiveName" | Out-Null
}
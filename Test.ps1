# Find the offline Windows installation
$WindowsDrive = Get-PSDrive -PSProvider FileSystem |
    Where-Object {
        $_.Root -ne $env:SystemDrive -and
        (Test-Path (Join-Path $_.Root 'Windows\System32\Config\SOFTWARE'))
    } |
    Select-Object -First 1

if (-not $WindowsDrive) {
    throw 'Windows volume not found.'
}

$WindowsRoot = Join-Path $WindowsDrive.Root 'Windows'

# Set these for the Capture Operating System Image step
$ts.Value('OSDTargetSystemDrive') = $WindowsDrive.Root.TrimEnd('\')
$ts.Value('OSDTargetSystemRoot') = $WindowsRoot
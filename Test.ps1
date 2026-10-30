
# OSD Live Log Collector

# Configuration
$Share = "\\fileserver.example.com\OSDLogs"

# Folders to monitor - add or remove paths
$LogPaths = @(
    "X:\Windows\Temp",
    "X:\SMSTSLog",
    "C:\Windows\CCM\Logs"
)

$Interval = 1

# Authenticate once
$Credential = Get-Credential -Message "Enter network share credentials"

try {
    New-PSDrive -Name OSD `
        -PSProvider FileSystem `
        -Root $Share `
        -Credential $Credential `
        -ErrorAction Stop | Out-Null
}
catch {
    Write-Host "Share connection failed: $($_.Exception.Message)"
    return
}

# Create machine folder
$Serial = (Get-WmiObject Win32_BIOS).SerialNumber -replace '[\\/:*?"<>|]', '_'
$Destination = "OSD:\$Serial"

New-Item -Path $Destination -ItemType Directory -Force | Out-Null

Write-Host "Collecting logs to $Destination"
Write-Host "Press Ctrl+C to stop."

# Continuously copy logs
while ($true) {

    foreach ($Path in $LogPaths) {

        if (-not (Test-Path -LiteralPath $Path)) {
            continue
        }

        Get-ChildItem -LiteralPath $Path -Filter "*.log" -File -Recurse -ErrorAction SilentlyContinue |
        ForEach-Object {

            $Source = $_.FullName

            # Preserve source folder structure
            $Relative = $Source.Substring($Path.TrimEnd('\').Length).TrimStart('\')
            $Folder = ($Path -replace '[:\\]', '_').Trim('_')

            $Target = Join-Path $Destination (Join-Path $Folder $Relative)
            $TargetFolder = Split-Path $Target -Parent

            try {
                New-Item -Path $TargetFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null

                # Read active log without locking it
                $InputFile = [IO.File]::Open(
                    $Source, 'Open', 'Read', 'ReadWrite'
                )

                try {
                    $OutputFile = [IO.File]::Open(
                        $Target, 'Create', 'Write', 'None'
                    )

                    try {
                        $InputFile.CopyTo($OutputFile)
                    }
                    finally {
                        $OutputFile.Dispose()
                    }
                }
                finally {
                    $InputFile.Dispose()
                }
            }
            catch {
                Write-Host "FAILED: $Source - $($_.Exception.Message)"
            }
        }
    }

    Start-Sleep -Seconds $Interval
}

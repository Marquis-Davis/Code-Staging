
# OSD Live Log Streamer
# PowerShell 5.1 / WinPE

$ShareRoot = "\\fileserver.example.com\OSDLogs"
$PollMilliseconds = 200

$LogPaths = @(
    "X:\Windows\Temp\SMSTSLog",
    "X:\SMSTSLog",
    "X:\Windows\Temp",
    "C:\_SMSTaskSequence\Logs",
    "C:\Windows\CCM\Logs",
    "C:\ProgramData\OSDFrontend\Logs"
)

$LogNames = @(
    "smsts.log",
    "OSDFrontEnd.log",
    "OSD-Email.log",
    "OSDMonitor.log"
)

# Identify device
$Serial = (Get-WmiObject Win32_BIOS).SerialNumber
$Serial = $Serial -replace '[\\/:*?"<>|]', '_'

if ([string]::IsNullOrWhiteSpace($Serial)) {
    $Serial = $env:COMPUTERNAME
}

$Session = Get-Date -Format "yyyyMMdd_HHmmss"

# Authenticate once
$Credential = Get-Credential -Message "Enter credentials for OSD log share"

try {
    New-PSDrive -Name OSDLogs `
        -PSProvider FileSystem `
        -Root $ShareRoot `
        -Credential $Credential `
        -ErrorAction Stop | Out-Null

    $Destination = "OSDLogs:\$Serial\$Session"

    New-Item -ItemType Directory -Path $Destination -Force -ErrorAction Stop | Out-Null

    Write-Host "Connected to share: $Destination" -ForegroundColor Green
}
catch {
    Write-Host "Share connection failed: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# Track file offsets independently
$Offsets = @{}

Write-Host "Streaming OSD logs every $PollMilliseconds ms..."
Write-Host "Press Ctrl+C to stop."

while ($true) {
    foreach ($Path in $LogPaths) {
        if (-not (Test-Path -LiteralPath $Path)) {
            continue
        }

        foreach ($Name in $LogNames) {
            $Source = Join-Path $Path $Name

            if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
                continue
            }

            try {
                $FolderName = $Path -replace '[:\\]', '_'
                $TargetFolder = Join-Path $Destination $FolderName

                if (-not (Test-Path -LiteralPath $TargetFolder)) {
                    New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null
                }

                $TargetFile = Join-Path $TargetFolder $Name

                $InputStream = [System.IO.File]::Open(
                    $Source,
                    [System.IO.FileMode]::Open,
                    [System.IO.FileAccess]::Read,
                    [System.IO.FileShare]::ReadWrite
                )

                try {
                    if (-not $Offsets.ContainsKey($Source)) {
                        $Offsets[$Source] = 0L
                    }

                    $Offset = [long]$Offsets[$Source]

                    if ($InputStream.Length -lt $Offset) {
                        $Offset = 0L
                    }

                    if ($InputStream.Length -gt $Offset) {
                        $InputStream.Seek($Offset, [System.IO.SeekOrigin]::Begin) | Out-Null

                        $OutputStream = [System.IO.File]::Open(
                            $TargetFile,
                            [System.IO.FileMode]::Append,
                            [System.IO.FileAccess]::Write,
                            [System.IO.FileShare]::Read
                        )

                        try {
                            $Buffer = New-Object byte[] 65536

                            while (($BytesRead = $InputStream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
                                $OutputStream.Write($Buffer, 0, $BytesRead)
                            }

                            $OutputStream.Flush()
                            $Offsets[$Source] = $InputStream.Position
                        }
                        finally {
                            $OutputStream.Dispose()
                        }
                    }
                }
                finally {
                    $InputStream.Dispose()
                }
            }
            catch {
                Write-Host "Stream failed: $Source - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    Start-Sleep -Milliseconds $PollMilliseconds
}

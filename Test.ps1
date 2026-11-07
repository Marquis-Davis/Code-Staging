
function Write-OSDAuthLog {
    param([string]$Message)

    try {
        if (-not $script:AuthLog) {

            $folder = if (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\MiniNT') {
                'X:\Windows\Temp\SMSTSLog'
            }
            else {
                "$env:SystemDrive\Temp\SMSTSLog"
            }

            New-Item -Path $folder -ItemType Directory -Force -ErrorAction Stop | Out-Null

            $ip = if ($labelIPAddress.Text -match '^IP:\s*(\d{1,3}(?:\.\d{1,3}){3})$') {
                $matches[1]
            }
            else {
                "NoIP-$env:COMPUTERNAME-$(Get-Date -Format 'yyyyMMddHHmmss')"
            }

            $script:AuthLog = Join-Path $folder "${ip}-OSDAuthentication.log"
        }

        Add-Content -LiteralPath $script:AuthLog `
            -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $Message" `
            -ErrorAction Stop
    }
    catch {
        Write-Warning "Authentication logging failed: $($_.Exception.Message)"
    }
}

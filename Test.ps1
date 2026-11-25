
try {
    $tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
    $script:SiteCode = [string]$tsenv.Value('_SMSTSSiteCode')

    if ($script:SiteCode -notmatch '^[A-Za-z0-9]{3}$') {
        throw 'TS site code unavailable'
    }
}
catch {
    Write-OSDAuthLog "TS detection failed: $($_.Exception.Message)"

    if ($script:isWinPE) { throw }

    $script:SiteCode = 'P01' # Replace with your PROD site code
    Write-OSDAuthLog "WARNING: Full OS test fallback using PROD site $script:SiteCode"
}

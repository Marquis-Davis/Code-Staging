# ------------------------------------------------------------
# Connect to ConfigMgr
# ------------------------------------------------------------

try {
    Write-Log "Execution account: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"

    $CMModule = Join-Path `
        $env:SMS_ADMIN_UI_PATH `
        "..\ConfigurationManager.psd1"

    Import-Module $CMModule -Force -ErrorAction Stop

    # SMS Provider machine name
    $ProviderMachineName = "cm-provider.example.com"

    if (-not (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
        New-PSDrive `
            -Name $SiteCode `
            -PSProvider CMSite `
            -Root $ProviderMachineName `
            -ErrorAction Stop | Out-Null
    }

    Set-Location "${SiteCode}:" -ErrorAction Stop

    Write-Log "Connected to ConfigMgr site $SiteCode."
}
catch {
    Write-Log "ERROR: ConfigMgr connection failed."
    Write-Log $_.Exception.ToString()
    return
}
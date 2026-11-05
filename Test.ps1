# Connect to ConfigMgr and reconcile package version

try {
    Write-Log "Runbook identity: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"

    $CMModule = Join-Path `
        (Split-Path $env:SMS_ADMIN_UI_PATH -Parent) `
        "ConfigurationManager.psd1"

    Import-Module $CMModule -Force -ErrorAction Stop

    $ProviderMachineName = "cm-provider.example.com"

    if (-not (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
        New-PSDrive -Name $SiteCode `
            -PSProvider CMSite `
            -Root $ProviderMachineName `
            -ErrorAction Stop | Out-Null
    }

    Set-Location "${SiteCode}:" -ErrorAction Stop

    $Package = Get-CMPackage -Id $PackageId -Fast -ErrorAction Stop

    if (-not $Package) {
        throw "ConfigMgr package not found."
    }

    Write-Log "ConfigMgr package version: $($Package.Version)"
    Write-Log "Defender source version: $NewVersion"

    if ([version]$Package.Version -lt [version]$NewVersion) {

        Write-Log "Updating ConfigMgr package version..."

        Set-CMPackage -Id $PackageId `
            -Version $NewVersion.ToString() `
            -ErrorAction Stop

        Write-Log "Redistributing Defender package..."

        Update-CMDistributionPoint -PackageId $PackageId `
            -ErrorAction Stop

        Write-Log "ConfigMgr update and redistribution initiated."
    }
    else {
        Write-Log "ConfigMgr package version is already current."
    }
}
catch {
    Write-Log "ERROR: ConfigMgr update failed."
    Write-Log $_.Exception.ToString()
    throw
}
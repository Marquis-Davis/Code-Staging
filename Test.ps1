# ------------------------------------------------------------
# Verify package exists
# ------------------------------------------------------------

try {
    $Package = Get-CMPackage -Id $PackageId -Fast -ErrorAction Stop

    if (-not $Package) {
        throw "ConfigMgr package $PackageId was not found."
    }

    Write-Log "ConfigMgr Package: $($Package.Name)"
    Write-Log "Package ID: $PackageId"
    Write-Log "Current ConfigMgr Version: $($Package.Version)"
    Write-Log "Defender Source Version: $NewVersion"

    if ([version]$Package.Version -lt [version]$NewVersion) {

        Write-Log "New Defender version detected. Updating package..."

        Set-CMPackage -Id $PackageId `
            -Version $NewVersion.ToString() `
            -ErrorAction Stop

        Write-Log "ConfigMgr package version updated to $NewVersion."

        # Refresh content on existing DPs
        Write-Log "Updating Defender Platform content on distribution points..."

        Update-CMDistributionPoint `
            -PackageId $PackageId `
            -ErrorAction Stop

        Write-Log "Distribution point update triggered successfully."
    }
    else {
        Write-Log "No newer Defender version. Skipping package update and redistribution."
    }
}
catch {
    Write-Log "ERROR: ConfigMgr package update failed."
    Write-Log $_.Exception.ToString()
    throw
}
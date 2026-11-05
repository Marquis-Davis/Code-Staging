# ------------------------------------------------------------
# Check if package source needs updating
# ------------------------------------------------------------

$SourceUpdateRequired = $NewVersion -gt $CurrentVersion

if (-not $SourceUpdateRequired) {
    Write-Log "Package source is already current: $CurrentVersion"
    Write-Log "Checking ConfigMgr package version..."
}
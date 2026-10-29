$ErrorActionPreference = 'Stop'

$Log = 'C:\Windows\System32\Sysprep\Panther\setuperr.log'

if (-not (Test-Path $Log)) {
    throw "Sysprep log not found: $Log"
}

$Packages = Get-Content $Log |
    Select-String 'SYSPRP Package (.+?) was installed for a user, but not provisioned for all users' |
    ForEach-Object {
        $_.Matches[0].Groups[1].Value
    } |
    Sort-Object -Unique

if (-not $Packages) {
    Write-Host 'No AppX Sysprep blockers found.'
    return
}

foreach ($PackageFullName in $Packages) {

    Write-Host "Removing Sysprep blocker: $PackageFullName"

    # Remove installed registrations
    Get-AppxPackage -AllUsers |
        Where-Object PackageFullName -eq $PackageFullName |
        Remove-AppxPackage -AllUsers -ErrorAction Continue

    # Remove provisioning only if this exact package is provisioned
    $Provisioned = Get-AppxProvisionedPackage -Online |
        Where-Object PackageName -eq $PackageFullName

    if ($Provisioned) {
        $Provisioned |
            Remove-AppxProvisionedPackage -Online -ErrorAction Continue
    }
}

Write-Host ''
Write-Host 'Cleanup complete. Retry Sysprep.'
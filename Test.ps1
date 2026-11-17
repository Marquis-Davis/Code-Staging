lImport-Module ActiveDirectory

$Accounts = @(
    "svc-OSDWebService",
    "svc-OSDDomainJoin"
)

$Report = foreach ($Account in $Accounts) {

    Get-ADUser -Identity $Account -Properties `
        Description,
        Enabled,
        PasswordNeverExpires,
        CannotChangePassword,
        ServicePrincipalName,
        MemberOf |
    Select-Object Name,
        SamAccountName,
        Enabled,
        Description,
        PasswordNeverExpires,
        CannotChangePassword,
        ServicePrincipalName,
        @{Name='Groups';Expression={
            ($_.MemberOf | Get-ADGroup | Select-Object -ExpandProperty Name) -join '; '
        }}
}

$Report | Format-List
$Report | Export-Csv "$env:USERPROFILE\Desktop\OSD-Accounts.csv" -NoTypeInformation
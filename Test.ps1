Import-Module ActiveDirectory

$Account = "svc-OSDDomainJoin"
$OU = "OU=Workstations,DC=example,DC=com"

(Get-Acl "AD:\$OU").Access |
    Where-Object {
        $_.IdentityReference -match [regex]::Escape($Account)
    } |
    Select-Object IdentityReference,
        ActiveDirectoryRights,
        AccessControlType,
        ObjectType,
        InheritanceType,
        IsInherited |
    Format-List
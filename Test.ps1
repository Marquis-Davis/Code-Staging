$user = Get-ADUser "<SERVICE_ACCOUNT>"
$dc = (Get-ADDomainController -Discover).HostName

Get-ADReplicationAttributeMetadata `
    -Object $user.DistinguishedName `
    -Server $dc |
Sort-Object LastOriginatingChangeTime -Descending |
Select-Object -First 15 AttributeName,
    LastOriginatingChangeTime,
    LastOriginatingChangeDirectoryServerIdentity,
    Version
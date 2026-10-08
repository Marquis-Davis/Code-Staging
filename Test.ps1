$domain = "example.com"
$dc = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain(
    (New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $domain))
).FindDomainController().Name

$dc
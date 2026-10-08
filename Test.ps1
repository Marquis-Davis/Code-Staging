$root = New-Object System.DirectoryServices.DirectoryEntry("LDAP://example.com/RootDSE", $null, $null, [System.DirectoryServices.AuthenticationTypes]::Anonymous)
$root.Properties["currentTime"][0]
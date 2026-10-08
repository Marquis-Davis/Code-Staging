$dc = [System.DirectoryServices.DirectoryEntry]::new("LDAP://dc01.example.com/RootDSE", $null, $null, [System.DirectoryServices.AuthenticationTypes]::Anonymous)
$dc.Properties["currentTime"][0]
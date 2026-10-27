$dnsServers = [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
    Where-Object OperationalStatus -eq 'Up' |
    ForEach-Object { $_.GetIPProperties().DnsAddresses } |
    Where-Object { $_.AddressFamily -eq 'InterNetwork' } |
    ForEach-Object { $_.ToString() } |
    Select-Object -Unique

foreach ($server in $dnsServers) {
    try {
        $root = [ADSI]"LDAP://$server/RootDSE"
        $time = $root.Properties['currentTime'].Value

        if ($time) {
            Write-Host "DC Found: $server"
            Write-Host "Trusted UTC Time: $time"
            break
        }
    }
    catch {
        Write-Host "No DC time from $server"
    }
}
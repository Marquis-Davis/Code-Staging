$nic = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
    Where-Object { $_.OperationalStatus -eq 'Up' -and $_.GetIPProperties().DnsSuffix } |
    Select-Object -First 1

$domain = $nic.GetIPProperties().DnsSuffix

Write-Host "Detected DNS suffix: $domain"

if ($domain -and (Get-Command Resolve-DnsName -ErrorAction SilentlyContinue)) {
    Resolve-DnsName "_ldap._tcp.dc._msdcs.$domain" -Type SRV -DnsOnly -QuickTimeout |
        Select-Object NameTarget, Priority
}
else {
    Write-Host 'DNS suffix or DNS lookup command unavailable.'
}
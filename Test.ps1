$ip = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
    Where-Object { $_.OperationalStatus -eq 'Up' -and $_.NetworkInterfaceType -ne 'Loopback' } |
    ForEach-Object { $_.GetIPProperties().UnicastAddresses } |
    Where-Object { $_.Address.AddressFamily -eq 'InterNetwork' -and $_.Address.ToString() -notlike '169.254.*' } |
    Select-Object -First 1

if ($ip) {
    $labelIPAddress.Text = "IP: $($ip.Address)"
}
else {
    $labelIPAddress.Text = "IP: Not assigned"
}
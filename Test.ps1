
# Check IP every 5 seconds
if (-not $script:NextIPCheck -or (Get-Date) -ge $script:NextIPCheck) {

    $script:NextIPCheck = (Get-Date).AddSeconds(5)

    $ip = [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
        Where-Object { $_.OperationalStatus -eq 'Up' -and $_.NetworkInterfaceType -ne 'Loopback' } |
        ForEach-Object { $_.GetIPProperties().UnicastAddresses } |
        Where-Object { $_.Address.AddressFamily -eq 'InterNetwork' -and $_.Address.ToString() -notlike '169.254.*' } |
        Select-Object -First 1

    $newIP = if ($ip) { $ip.Address.ToString() } else { 'Not assigned' }
    $oldIP = $labelIPAddress.Text -replace '^IP:\s*', ''

    if ($oldIP -ne $newIP) {
        Write-OSDAuthLog "IP changed: $oldIP -> $newIP"
        $labelIPAddress.Text = "IP: $newIP"
    }
}

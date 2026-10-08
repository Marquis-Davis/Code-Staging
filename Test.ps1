$server = "time.windows.com"
$udp = New-Object System.Net.Sockets.UdpClient
$udp.Client.ReceiveTimeout = 3000
$udp.Connect($server, 123)
$data = New-Object byte[] 48
$data[0] = 0x1B
[void]$udp.Send($data, 48)
$endpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
$response = $udp.Receive([ref]$endpoint)
$udp.Close()
"Received $($response.Length) bytes"
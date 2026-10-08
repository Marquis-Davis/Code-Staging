$socket = New-Object System.Net.Sockets.Socket -ArgumentList @('InterNetwork','Stream','Tcp')
$socket.Connect("example.com",389)
$socket.Connected
$socket.Close()
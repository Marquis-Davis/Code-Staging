$Serial = (Get-CimInstance Win32_BIOS).SerialNumber.Trim()
$Serial = $Serial -replace '[^a-zA-Z0-9]', ''

$ComputerName = "WK$Serial"
$Destination = "Z:\$ComputerName"
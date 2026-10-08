$seconds = [BitConverter]::ToUInt32([byte[]]($response[43..40]), 0)
$ntpTime = ([datetime]"1900-01-01").AddSeconds($seconds)
$ntpTime
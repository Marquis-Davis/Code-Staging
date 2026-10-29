
Registry('HKLM:\SOFTWARE\Microsoft\SMS\DP')
| where Property == 'RamDiskTFTPBlockSize' or Property == 'RamDiskTFTPWindowSize'
| project Device, Property, Value

Get-AppxPackage -AllUsers Microsoft.MicrosoftEdge.Stable |
    Select-Object PackageFullName, PackageUserInformation

Get-AppxPackage Microsoft.MicrosoftEdge.Stable |
    Remove-AppxPackage

& "C:\Windows\System32\Sysprep\Sysprep.exe" /generalize /oobe /shutdown
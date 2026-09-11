Get-ComputerInfo |
Select WindowsProductName, WindowsVersion, OsBuildNumber, OsArchitecture

Get-WindowsOptionalFeature -Online |
Where-Object FeatureName -match 'NetFx' |
Select FeatureName, State
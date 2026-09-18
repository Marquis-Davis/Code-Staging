$OSBuildPath = "Registry::HKEY_LOCAL_MACHINE\$HiveName\Microsoft\Windows NT\CurrentVersion"

$OSBuild = Get-ItemPropertyValue `
    -Path $OSBuildPath `
    -Name 'CurrentBuild'
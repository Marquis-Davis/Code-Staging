Registry('HKLM:\SOFTWARE\ExampleCompany\OSD')
| where Property == 'ImageInstalled'
| project Device, ImageInstalled = Value,
    InstallYear = substring(Value, indexof(Value, ' ') - 4, 4)
| where InstallYear > '2026'
    or (InstallYear == '2026'
        and (ImageInstalled startswith '11/'
            or ImageInstalled startswith '12/'))
| join kind=leftouter (
    Registry('HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion')
    | where Property == 'DisplayVersion'
    | project Device, WindowsVersion = Value
)
| project Device, ImageInstalled, WindowsVersion
| order by Device asc
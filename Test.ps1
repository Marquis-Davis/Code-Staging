
# Monthly OS Image QA Report
# Run after OSD completes. No parameters or prompts.

$folder = 'C:\Temp'
New-Item -ItemType Directory -Path $folder -Force | Out-Null

$file = Join-Path $folder ("OSImageQA_{0}_{1}.txt" -f $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd_HHmmss'))
$report = [System.Collections.Generic.List[string]]::new()

# To add a check later, use: Add-Line 'Check Name' $value
function Add-Line($name, $value) {
    $script:report.Add(('{0,-19}: {1}' -f $name, $value))
}

$report.Add('MONTHLY OS IMAGE QA REPORT')
$report.Add('========================================')

Add-Line 'Computer' $env:COMPUTERNAME
Add-Line 'Report Date' (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

# Windows and monthly patches
$os = Get-CimInstance Win32_OperatingSystem
$win = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'

Add-Line 'Windows OS' $os.Caption
Add-Line 'Windows Release' $win.DisplayVersion
Add-Line 'Windows Build' ("{0}.{1}" -f $win.CurrentBuild, $win.UBR)
Add-Line 'Last Boot' $os.LastBootUpTime

try {
    $kbs = @(Get-HotFix -ErrorAction Stop |
        Sort-Object InstalledOn -Descending |
        Select-Object -First 5 -ExpandProperty HotFixID)

    Add-Line 'Recent KBs' $(if ($kbs.Count) { $kbs -join ', ' } else { 'None returned' })
} catch {
    Add-Line 'Recent KBs' 'Unable to query'
}

# ConfigMgr client
$ccm = Get-Service CcmExec -ErrorAction SilentlyContinue
$ccmStatus = if ($ccm) { [string]$ccm.Status } else { 'Not installed' }

Add-Line 'ConfigMgr Client' $ccmStatus

try {
    $ccmVersion = (Get-CimInstance -Namespace root\ccm -ClassName SMS_Client -ErrorAction Stop).ClientVersion
    Add-Line 'ConfigMgr Version' $ccmVersion
} catch {
    Add-Line 'ConfigMgr Version' 'Unavailable'
}

# Pending servicing reboot
$reboot = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or
          (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')

Add-Line 'Pending Reboot' $(if ($reboot) { 'Yes' } else { 'No' })

# Local Administrators group
$report.Add('----------------------------------------')
$report.Add('LOCAL ADMINISTRATORS')

try {
    $members = @(Get-LocalGroupMember -SID 'S-1-5-32-544' -ErrorAction Stop)

    foreach ($member in $members) {
        $status = 'N/A (group or external account)'

        if ($member.ObjectClass -eq 'User' -and $member.PrincipalSource -eq 'Local') {
            try {
                $user = Get-LocalUser -SID $member.SID -ErrorAction Stop
                $status = if ($user.Enabled) { 'Enabled' } else { 'Disabled' }
            } catch {
                $status = 'Unknown'
            }
        }

        Add-Line 'Admin Member' ("{0} [{1}]" -f $member.Name, $status)
    }

    if (-not $members.Count) {
        Add-Line 'Admin Member' 'None found'
    }
} catch {
    Add-Line 'Admin Member' 'Unable to query'
}

# Firewall profiles
$report.Add('----------------------------------------')
$report.Add('FIREWALL PROFILES')

try {
    foreach ($profile in (Get-NetFirewallProfile -ErrorAction Stop)) {
        Add-Line $profile.Name ("Enabled={0}; Inbound={1}; Outbound={2}" -f `
            $profile.Enabled, $profile.DefaultInboundAction, $profile.DefaultOutboundAction)
    }
} catch {
    Add-Line 'Firewall' 'Unable to query'
}

# Microsoft Defender
$report.Add('----------------------------------------')
$report.Add('MICROSOFT DEFENDER')

try {
    $defender = Get-MpComputerStatus -ErrorAction Stop

    Add-Line 'Running Mode' $defender.AMRunningMode
    Add-Line 'Product Version' $defender.AMProductVersion
    Add-Line 'Engine Version' $defender.AMEngineVersion
    Add-Line 'Signature Version' $defender.AntivirusSignatureVersion
    Add-Line 'Signature Updated' $defender.AntivirusSignatureLastUpdated
    Add-Line 'Antivirus Enabled' $defender.AntivirusEnabled
    Add-Line 'Realtime Enabled' $defender.RealTimeProtectionEnabled
} catch {
    Add-Line 'Defender Status' 'Unable to query'
}

# .NET Framework features and runtime
$report.Add('----------------------------------------')
$report.Add('.NET FRAMEWORK')

foreach ($feature in @('NetFx3', 'NetFx4-AdvSrvs')) {
    try {
        $state = (Get-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction Stop).State
        Add-Line $feature $state
    } catch {
        Add-Line $feature 'Unable to query (try elevated PowerShell)'
    }
}

try {
    $net4 = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -ErrorAction Stop
    Add-Line '.NET 4.x Version' $net4.Version
} catch {
    Add-Line '.NET 4.x Version' 'Not found'
}

# Microsoft Edge and PowerShell versions
$report.Add('----------------------------------------')
$report.Add('BROWSER AND POWERSHELL')

$edgePaths = @(
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
)

$edge = $edgePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

Add-Line 'Microsoft Edge' $(if ($edge) { (Get-Item $edge).VersionInfo.ProductVersion } else { 'Not found' })

try {
    $ps5 = & "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
    Add-Line 'Windows PowerShell' $ps5
} catch {
    Add-Line 'Windows PowerShell' 'Unable to query'
}

$pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
$pwshPath = if ($pwsh) { $pwsh.Source } else { "$env:ProgramFiles\PowerShell\7\pwsh.exe" }

if (Test-Path $pwshPath) {
    try {
        $ps7 = & $pwshPath -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
        Add-Line 'PowerShell 7+' $ps7
    } catch {
        Add-Line 'PowerShell 7+' 'Unable to query'
    }
} else {
    Add-Line 'PowerShell 7+' 'Not installed'
}

# End of report
$report.Add('========================================')

# Save and open report
$report | Set-Content -Path $file -Encoding UTF8
Start-Process notepad.exe -ArgumentList ('"{0}"' -f $file)

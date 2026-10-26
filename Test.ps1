
# Monthly OS Image QA Report
# Run after the QA task sequence completes.
# No command-line parameters or user input required.

$reportFolder = 'C:\Temp'
$serviceNowUrl = ''  # Add your ServiceNow URL once.

New-Item -Path $reportFolder -ItemType Directory -Force | Out-Null

$computer = $env:COMPUTERNAME
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$reportPath = Join-Path $reportFolder "OSImageValidation_${computer}_${timestamp}.html"
$checks = @()

# Windows details
$os = Get-CimInstance Win32_OperatingSystem
$windows = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$release = [string]$windows.DisplayVersion
$build = '{0}.{1}' -f $windows.CurrentBuild, $windows.UBR

$checks += [pscustomobject]@{
    Check = 'Windows OS'; Expected = 'Windows 11'; Actual = $os.Caption
    Result = $(if ($os.Caption -match 'Windows 11') { 'PASS' } else { 'FAIL' })
}
$checks += [pscustomobject]@{
    Check = 'Windows edition'; Expected = 'Enterprise'; Actual = $windows.EditionID
    Result = $(if ($windows.EditionID -match '^Enterprise') { 'PASS' } else { 'FAIL' })
}
$checks += [pscustomobject]@{
    Check = 'Windows release'; Expected = 'Recorded for QA'; Actual = $release; Result = 'INFO'
}
$checks += [pscustomobject]@{
    Check = 'OS build + UBR'; Expected = 'Recorded for QA'; Actual = $build; Result = 'INFO'
}

# Recent hotfixes, informational only
try {
    $kbs = @(Get-HotFix -ErrorAction Stop |
        Sort-Object InstalledOn -Descending |
        Select-Object -First 5 -ExpandProperty HotFixID)
    $kbList = if ($kbs.Count) { $kbs -join ', ' } else { 'No hotfixes returned' }
} catch {
    $kbList = 'Unable to retrieve hotfixes'
}
$checks += [pscustomobject]@{
    Check = 'Recent hotfixes'; Expected = 'Reference only'; Actual = $kbList; Result = 'INFO'
}

# ConfigMgr client
$ccm = Get-Service -Name CcmExec -ErrorAction SilentlyContinue
$ccmStatus = if ($ccm) { [string]$ccm.Status } else { 'Not installed' }
$checks += [pscustomobject]@{
    Check = 'ConfigMgr client'; Expected = 'Running'; Actual = $ccmStatus
    Result = $(if ($ccmStatus -eq 'Running') { 'PASS' } else { 'FAIL' })
}

# Pending servicing reboot
$rebootPending = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or
                 (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')
$checks += [pscustomobject]@{
    Check = 'Pending servicing reboot'; Expected = 'No'; Actual = $(if ($rebootPending) { 'Yes' } else { 'No' })
    Result = $(if ($rebootPending) { 'FAIL' } else { 'PASS' })
}

# Component store health
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    try {
        $imageHealth = [string](Repair-WindowsImage -Online -CheckHealth -ErrorAction Stop).ImageHealthState
        if (-not $imageHealth) { $imageHealth = 'Unknown' }
        $imageResult = if ($imageHealth -eq 'Healthy') { 'PASS' } else { 'FAIL' }
    } catch {
        $imageHealth = 'Unable to check: ' + $_.Exception.Message
        $imageResult = 'INFO'
    }
} else {
    $imageHealth = 'Skipped: run as Administrator to check'
    $imageResult = 'INFO'
}
$checks += [pscustomobject]@{
    Check = 'Component store'; Expected = 'Healthy'; Actual = $imageHealth; Result = $imageResult
}

$failed = @($checks | Where-Object Result -eq 'FAIL').Count
$overall = if ($failed) { 'FAIL' } else { 'PASS' }

# Generate HTML
function H($value) { [System.Net.WebUtility]::HtmlEncode([string]$value) }

$rows = foreach ($item in $checks) {
    '<tr><td>{0}</td><td>{1}</td><td>{2}</td><td class="{3}">{3}</td></tr>' -f `
        (H $item.Check), (H $item.Expected), (H $item.Actual), $item.Result
}

$html = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Monthly OS Image QA Report</title>
<style>
body { font: 14px 'Segoe UI',Arial,sans-serif; margin: 32px; color: #243141; }
h1 { margin-bottom: 8px; }
.summary { font-size: 18px; font-weight: bold; margin: 20px 0; }
table { width: 100%; border-collapse: collapse; }
th,td { border-bottom: 1px solid #dce2e8; padding: 10px; text-align: left; }
th { background: #eef2f7; }
.PASS { color: #187a43; font-weight: bold; }
.FAIL { color: #b42318; font-weight: bold; }
.INFO { color: #526477; font-weight: bold; }
.note { color: #526477; font-size: 12px; margin-top: 24px; }
</style>
</head>
<body>
<h1>Monthly OS Image QA Report</h1>
<p><b>Computer:</b> $(H $computer)<br>
<b>Generated:</b> $(H (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))<br>
<b>Last boot:</b> $(H $os.LastBootUpTime)</p>
<div class="summary">Automated health checks: <span class="$overall">$overall</span></div>
<table>
<thead><tr><th>Check</th><th>Expected</th><th>Detected</th><th>Result</th></tr></thead>
<tbody>$($rows -join "`n")</tbody>
</table>
<p class="note">The installed release/build and recent hotfixes are recorded, not certified against a monthly approved baseline. Task sequence success, actual WIM source and application/driver smoke tests must be verified separately.</p>
</body>
</html>
"@

Set-Content -Path $reportPath -Value $html -Encoding UTF8

# Open report automatically
Start-Process -FilePath $reportPath

# Open ServiceNow if URL is configured
if ($serviceNowUrl.Trim()) {
    Start-Process -FilePath $serviceNowUrl
}

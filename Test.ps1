
# Monthly OS Image Validation
# Run as Administrator after OSD completes

param(
    [string]$ExpectedVersion = '',
    [string]$ExpectedBuild = '',
    [string]$ExpectedEdition = 'Enterprise',
    [string]$ExpectedKB = '',
    [string]$Ticket = '',
    [string]$OutputFolder = "$env:PUBLIC\Documents\OSImageValidation"
)

$ErrorActionPreference = 'Stop'
$checks = @()

function Add-Check {
    param(
        [string]$Name,
        [string]$Expected,
        [string]$Actual,
        [string]$Result
    )

    $script:checks += [pscustomobject]@{
        Check    = $Name
        Expected = $Expected
        Actual   = $Actual
        Result   = $Result
    }
}

function To-HtmlText {
    param([object]$Value)
    [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

# Windows version and build

$os = Get-CimInstance Win32_OperatingSystem
$version = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$release = [string]$version.DisplayVersion
$actualBuild = '{0}.{1}' -f $version.CurrentBuild, $version.UBR

Add-Check 'Windows edition' $ExpectedEdition $os.Caption $(
    if ($os.Caption -match [regex]::Escape($ExpectedEdition)) {
        'PASS'
    } else {
        'FAIL'
    }
)

if ($ExpectedVersion) {
    Add-Check 'Windows release' $ExpectedVersion $release $(
        if ($release -eq $ExpectedVersion) { 'PASS' } else { 'FAIL' }
    )
} else {
    Add-Check 'Windows release' 'No approved baseline supplied' $release 'INFO'
}

if ($ExpectedBuild) {
    Add-Check 'OS build + UBR' $ExpectedBuild $actualBuild $(
        if ($actualBuild -eq $ExpectedBuild) { 'PASS' } else { 'FAIL' }
    )
} else {
    Add-Check 'OS build + UBR' 'No approved baseline supplied' $actualBuild 'INFO'
}

# Recently installed hotfixes (informational)

try {
    $recentUpdates = @(
        Get-HotFix -ErrorAction Stop |
        Sort-Object InstalledOn -Descending |
        Select-Object -First 3 -ExpandProperty HotFixID
    )

    $recentKBs = if ($recentUpdates.Count) {
        $recentUpdates -join ', '
    } else {
        'None returned'
    }
} catch {
    $recentKBs = 'Could not query update history'
}

Add-Check 'Recent hotfixes (reference only)' 'Information only' $recentKBs 'INFO'

# ConfigMgr client service

$ccm = Get-Service CcmExec -ErrorAction SilentlyContinue

$ccmStatus = if ($ccm) {
    [string]$ccm.Status
} else {
    'Not installed'
}

Add-Check 'ConfigMgr client service' 'Running' $ccmStatus $(
    if ($ccmStatus -eq 'Running') { 'PASS' } else { 'FAIL' }
)

# Windows component store health

try {
    $health = [string](Repair-WindowsImage -Online -CheckHealth -ErrorAction Stop).ImageHealthState

    if (-not $health) {
        $health = 'Unknown'
    }
} catch {
    $health = 'Unable to check: ' + $_.Exception.Message
}

Add-Check 'Component store health' 'Healthy' $health $(
    if ($health -eq 'Healthy') { 'PASS' } else { 'FAIL' }
)

# Pending Windows servicing reboot

$rebootKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
)

$pendingReboot = @($rebootKeys | Where-Object {
    Test-Path $_
}).Count -gt 0

Add-Check 'Windows servicing reboot pending' 'No' $(
    if ($pendingReboot) { 'Yes' } else { 'No' }
) $(
    if ($pendingReboot) { 'FAIL' } else { 'PASS' }
)

# Calculate results

$failCount = @($checks | Where-Object Result -eq 'FAIL').Count
$overall = if ($failCount -eq 0) { 'PASS' } else { 'FAIL' }

$compliance = if ($ExpectedVersion -and $ExpectedBuild) {
    'Compared with supplied approved release and build'
} else {
    'NOT VERIFIED: approved release/build not supplied'
}

$generated = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$booted = $os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss')

# Create report folder

New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$baseName = 'OSImageValidation_{0}_{1}' -f `
    $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd_HHmmss')

$htmlPath = Join-Path $OutputFolder ($baseName + '.html')
$textPath = Join-Path $OutputFolder ($baseName + '.txt')

# Build HTML table

$rows = foreach ($check in $checks) {
    '<tr><td>{0}</td><td>{1}</td><td>{2}</td><td class="{3}">{3}</td></tr>' -f `
        (To-HtmlText $check.Check),
        (To-HtmlText $check.Expected),
        (To-HtmlText $check.Actual),
        $check.Result
}

# HTML report

$html = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Monthly OS Image Validation</title>
<style>
body { font-family: Segoe UI, Arial, sans-serif; margin: 32px; color: #243141; }
h1 { margin-bottom: 6px; }
.sub, .note { color: #64748b; }
.summary { font-size: 20px; font-weight: bold; margin: 20px 0; }
.PASS { color: #147d44; font-weight: bold; }
.FAIL { color: #bd2e29; font-weight: bold; }
.INFO { color: #475569; font-weight: bold; }
table { border-collapse: collapse; width: 100%; margin-top: 14px; }
th, td { text-align: left; padding: 10px; border-bottom: 1px solid #d9e1e8; }
th { background: #edf2f7; }
.note { font-size: 13px; margin-top: 24px; }
</style>
</head>
<body>
<h1>Monthly OS Image Validation</h1>
<div class="sub">Generated $(To-HtmlText $generated) | Device $(To-HtmlText $env:COMPUTERNAME) | Ticket $(To-HtmlText $Ticket)</div>
<div class="summary">Device health checks: <span class="$overall">$overall</span> ($failCount failed)</div>
<p><strong>Installed OS:</strong> $(To-HtmlText $os.Caption)<br>
<strong>OS build:</strong> $(To-HtmlText $actualBuild)<br>
<strong>Patch compliance:</strong> $(To-HtmlText $compliance)<br>
<strong>Expected KB (reference):</strong> $(To-HtmlText $(if ($ExpectedKB) { $ExpectedKB } else { 'Not supplied' }))<br>
<strong>Last boot:</strong> $(To-HtmlText $booted)</p>
<table>
<thead>
<tr>
<th>Validation</th>
<th>Expected</th>
<th>Actual</th>
<th>Result</th>
</tr>
</thead>
<tbody>$($rows -join "`n")</tbody>
</table>
<p class="note">This report checks the running OS, not the WIM source. Review task sequence success and functional smoke tests separately. The build can only be certified against the monthly approved release when a baseline is supplied.</p>
</body>
</html>
"@

Set-Content $htmlPath $html -Encoding UTF8

# Text report

$text = @(
    'MONTHLY OS IMAGE VALIDATION',
    "Generated: $generated",
    "Device: $env:COMPUTERNAME",
    "Ticket: $Ticket",
    "Installed OS: $($os.Caption)",
    "OS build: $actualBuild",
    "Patch compliance: $compliance",
    "Last boot: $booted",
    "Device health result: $overall ($failCount failed)",
    '',
    'CHECKS'
)

$text += $checks | ForEach-Object {
    '{0}: {1} | Expected: {2} | Actual: {3}' -f `
        $_.Result, $_.Check, $_.Expected, $_.Actual
}

$text += ''
$text += 'Note: Confirm task sequence success and functional smoke tests separately.'

Set-Content $textPath $text -Encoding UTF8

# Display results

Write-Host "Device health: $overall" -ForegroundColor $(
    if ($overall -eq 'PASS') { 'Green' } else { 'Red' }
)

Write-Host "Patch compliance: $compliance"
Write-Host "HTML report: $htmlPath"
Write-Host "Text report: $textPath"

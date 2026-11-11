l$folderName = $txtComputerName.Text.Trim()

if ([string]::IsNullOrWhiteSpace($folderName) -or $folderName -like 'MININT-*') {
    $folderName = $txtIP.Text.Trim()
}

$txtDestination.Text = Join-Path $RootPath $folderName
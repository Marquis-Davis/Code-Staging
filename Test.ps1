$Credential = Get-Credential -Message "Enter share credentials"

if (Get-PSDrive Z -ErrorAction SilentlyContinue) {
    Remove-PSDrive Z -Force
}

New-PSDrive -Name Z `
    -PSProvider FileSystem `
    -Root $Share `
    -Credential $Credential `
    -Scope Global `
    -ErrorAction Stop | Out-Null

if (-not (Test-Path "Z:\")) {
    throw "Cannot access network share."
}
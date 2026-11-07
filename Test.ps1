# Keep the latest 3 published exports
Get-ChildItem -LiteralPath $Folder -Filter 'BuildSegments-*.json' -File |
    Sort-Object Name -Descending |
    Select-Object -Skip 3 |
    Remove-Item -ErrorAction Stop
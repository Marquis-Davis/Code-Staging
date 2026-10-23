1..15 | ForEach-Object {
    Get-Process TSBackground -ErrorAction SilentlyContinue |
        Select-Object Id, MainWindowHandle, MainWindowTitle
    Start-Sleep -Seconds 1
}
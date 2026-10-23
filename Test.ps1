1..10 | ForEach-Object {
    $h = [WinFocus]::GetForegroundWindow()
    [uint32]$p = 0
    [void][WinFocus]::GetWindowThreadProcessId($h, [ref]$p)

    [PSCustomObject]@{
        Handle  = $h.ToInt64()
        PID     = $p
        Process = (Get-Process -Id $p -ErrorAction SilentlyContinue).ProcessName
    }

    Start-Sleep -Seconds 1
}
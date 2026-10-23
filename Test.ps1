Add-Type @'
using System;
using System.Runtime.InteropServices;

public class WinFocus
{
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(
        IntPtr hWnd, out uint processId);
}
'@

$hwnd = [WinFocus]::GetForegroundWindow()
[uint32]$processId = 0

[void][WinFocus]::GetWindowThreadProcessId(
    $hwnd, [ref]$processId)

[PSCustomObject]@{
    Handle  = $hwnd.ToInt64()
    PID     = $processId
    Process = (Get-Process -Id $processId).ProcessName
}
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;

public class WindowFinder
{
    public delegate bool EnumCallback(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumCallback callback, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int maxCount);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
}
'@

$pidTS = (Get-Process TSBackground).Id

$callback = [WindowFinder+EnumCallback]{
    param($hWnd, $lParam)

    [uint32]$windowPid = 0
    [void][WindowFinder]::GetWindowThreadProcessId($hWnd, [ref]$windowPid)

    if ($windowPid -eq $pidTS) {
        $title = New-Object System.Text.StringBuilder 256
        [void][WindowFinder]::GetWindowText($hWnd, $title, 256)

        [PSCustomObject]@{
            Handle  = $hWnd.ToInt64()
            Title   = $title.ToString()
            Visible = [WindowFinder]::IsWindowVisible($hWnd)
        } | Format-List
    }

    return $true
}

[void][WindowFinder]::EnumWindows($callback, [IntPtr]::Zero)
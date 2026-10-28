
$timerClock_Tick = {
    $labelClock.Text = Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt'

    if ($labelBuildStatus.Text -like 'Checking*') {
        $script:dots = ($script:dots + 1) % 4
        $labelBuildStatus.Text = 'Checking' + ('.' * $script:dots)
    }
}

$formAuthentication_Load = {
    $script:isWinPE = Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\MiniNT'

    if ($script:isWinPE) {
        $buttonCancelRestart.Text = 'Cancel && Restart'
        $tooltipCancel.SetToolTip($buttonCancelRestart, 'Cancel authentication and restart this computer.')
    }
    else {
        $buttonCancelRestart.Text = 'Cancel && Exit'
        $tooltipCancel.SetToolTip($buttonCancelRestart, 'Cancel authentication and close this window.')
    }
}
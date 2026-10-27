$script:isWinPE = Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\MiniNT'

if ($script:isWinPE) {
    $buttonCancel.Text = 'Cancel && Restart'
}
else {
    $buttonCancel.Text = 'Cancel && Exit'
}


$buttonCancel_Click = {

    if ($script:isWinPE) {

        $result = [System.Windows.Forms.MessageBox]::Show(
            "Cancel authentication and restart this computer?",
            "Confirm Restart",
            "YesNo",
            "Warning"
        )

        if ($result -eq 'Yes') {
            wpeutil.exe Reboot
        }
    }
    else {
        $formAuthentication.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $formAuthentication.Close()
    }
}
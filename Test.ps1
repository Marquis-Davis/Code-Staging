if ([string]::IsNullOrWhiteSpace($textboxUsername.Text) -or
    [string]::IsNullOrWhiteSpace($textboxPassword.Text)) {

    [System.Windows.Forms.MessageBox]::Show(
        "Please enter both a username and password.",
        "Authentication Required",
        "OK",
        "Warning"
    )
    return
}
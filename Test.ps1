$buttonAuthenticate_Click = {

    if ([string]::IsNullOrWhiteSpace($textboxUsername.Text) -or
        [string]::IsNullOrWhiteSpace($textboxPassword.Text)) {

        [System.Windows.Forms.MessageBox]::Show(
            "Please enter both a username and password.",
            "Authentication Required",
            "OK",
            "Warning"
        )

        if ([string]::IsNullOrWhiteSpace($textboxUsername.Text)) {
            $textboxUsername.Focus()
        }
        else {
            $textboxPassword.Focus()
        }

        return
    }

    # Existing AD authentication logic goes here
}
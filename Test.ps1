l$securePassword = ConvertTo-SecureString $textboxPassword.Text -AsPlainText -Force

$script:AuthCredential = [PSCredential]::new(
    $textboxUsername.Text.Trim(),
    $securePassword
)

$formAuthentication.DialogResult = [System.Windows.Forms.DialogResult]::OK
$formAuthentication.Close()
# Validate credentials before closing the form
$context = $null

try {
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement

    $context = [System.DirectoryServices.AccountManagement.PrincipalContext]::new(
        [System.DirectoryServices.AccountManagement.ContextType]::Domain,
        $global:Domain
    )

    $valid = $context.ValidateCredentials(
        $textboxUsername.Text.Trim(),
        $textboxPassword.Text
    )

    if (-not $valid) {
        [void][System.Windows.Forms.MessageBox]::Show(
            'Authentication failed. Please retry.',
            'Authentication',
            'OK',
            'Warning'
        )
        return
    }
}
catch {
    [void][System.Windows.Forms.MessageBox]::Show(
        'Unable to contact or validate against the domain. Please retry.',
        'Authentication',
        'OK',
        'Warning'
    )
    return
}
finally {
    if ($context) {
        $context.Dispose()
    }
}
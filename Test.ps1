# Service account for QA testing
$username = 'EXAMPLE\svc_OSDLogs'
$password = 'REPLACE_WITH_TEST_PASSWORD'

$secure = ConvertTo-SecureString $password -AsPlainText -Force
$cred = [PSCredential]::new($username, $secure)
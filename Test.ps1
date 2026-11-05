Write-Log "ERROR: ConfigMgr connection failed."
Write-Log "Execution account: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Log "Failure details: $($_.Exception.ToString())"
throw
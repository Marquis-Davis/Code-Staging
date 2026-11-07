
$linkLabelSendLogs_LinkClicked = {

    # NAS connection
    $nas = '\\nas01.example.com\OSDContent'
    $username = 'EXAMPLE\svc_OSDLogs'
    $password = 'REPLACE_WITH_PASSWORD'

    Write-OSDAuthLog "Send Logs requested"
    $mapped = $false

    try {
        $secure = ConvertTo-SecureString $password -AsPlainText -Force
        $cred = New-Object PSCredential($username, $secure)

        New-PSDrive -Name AuthHelp -PSProvider FileSystem `
            -Root $nas -Credential $cred -ErrorAction Stop | Out-Null
        $mapped = $true

        # Device folder: IP or serial fallback
        $id = $labelIPAddress.Text -replace '^IP:\s*', ''

        if ($id -notmatch '^(\d{1,3}\.){3}\d{1,3}$') {
            $id = (Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue).SerialNumber
        }

        if ([string]::IsNullOrWhiteSpace($id)) {
            $id = $env:COMPUTERNAME
        }

        $id = $id.Trim() -replace '[\\/:*?"<>|]', '_'
        $folder = Join-Path $nas "OSDAuthLogs\$id"

        New-Item -Path $folder -ItemType Directory -Force -ErrorAction Stop | Out-Null

        # Increment filenames without overwriting
        $name = [IO.Path]::GetFileNameWithoutExtension($script:AuthLog)
        $i = 1

        do {
            $destination = Join-Path $folder ("{0}_{1:D3}.log" -f $name, $i++)
        } while (Test-Path -LiteralPath $destination)

        [IO.File]::Copy($script:AuthLog, $destination, $false)

        Write-OSDAuthLog "Logs sent successfully: $destination"

        [void][Windows.Forms.MessageBox]::Show(
            "Logs Sent to ContentSource", "OSD Authentication",
            "OK", "Information"
        )
    }
    catch {
        Write-OSDAuthLog "Log upload FAILED: $($_.Exception.Message)"

        [void][Windows.Forms.MessageBox]::Show(
            "Unable to send logs. Check the local authentication log.",
            "Upload Failed", "OK", "Error"
        )
    }
    finally {
        if ($mapped) {
            Remove-PSDrive -Name AuthHelp -ErrorAction SilentlyContinue
        }
    }
}

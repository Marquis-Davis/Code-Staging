
$linkLabelSendLogs_LinkClicked = {

    # NAS destination
    $nas = '\\nas01.example.com\OSDContent'

    Write-OSDAuthLog "Technician requested log upload"

    try {
        $cred = Get-Credential -Message "Enter credentials to send logs"
        if (-not $cred) { return }

        # Connect to NAS
        New-PSDrive -Name AuthHelp -PSProvider FileSystem `
            -Root $nas -Credential $cred -ErrorAction Stop | Out-Null

        # Use IP or serial number
        $id = $labelIPAddress.Text -replace '^IP:\s*', ''

        if ($id -notmatch '^\d{1,3}(\.\d{1,3}){3}$') {
            $id = (Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue).SerialNumber
        }

        if (-not $id) { $id = $env:COMPUTERNAME }

        $id = $id -replace '[\\/:*?"<>|]', '_'

        # Create device folder
        $folder = "AuthHelp:\OSDAuthLogs\$id"
        New-Item -Path $folder -ItemType Directory -Force -ErrorAction Stop | Out-Null

        # Increment filename without overwriting
        $name = [IO.Path]::GetFileNameWithoutExtension($script:AuthLog)
        $i = 1

        do {
            $destination = Join-Path $folder ("{0}_{1:D3}.log" -f $name, $i)
            $i++
        }
        while (Test-Path $destination)

        # Copy current authentication log
        Copy-Item -LiteralPath $script:AuthLog -Destination $destination -ErrorAction Stop

        Write-OSDAuthLog "Log upload successful: $destination"

        [void][Windows.Forms.MessageBox]::Show(
            "Logs Sent to ContentSource",
            "OSD Authentication"
        )
    }
    catch {
        Write-OSDAuthLog "Log upload failed: $($_.Exception.Message)"

        [void][Windows.Forms.MessageBox]::Show(
            "Unable to send logs. Check NAS access or credentials.",
            "Upload Failed"
        )
    }
    finally {
        Remove-PSDrive -Name AuthHelp -ErrorAction SilentlyContinue
    }
}

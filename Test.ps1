$script:AuthCredential = $null

if ((Show-OSD-Authentication_psf) -ne 'OK') {
    return
}

$creds = $script:AuthCredential
$script:AuthCredential = $null
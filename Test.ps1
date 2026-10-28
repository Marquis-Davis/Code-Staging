function Set-BuildSegmentStatus {
    param($Status)

    $pictureBoxBuildChecking.Visible = ($Status -eq 'Checking')
    $pictureBoxBuildApproved.Visible = ($Status -eq 'Approved')
    $pictureBoxBuildDenied.Visible = ($Status -eq 'Denied')

    switch ($Status) {
        'Checking' {
            $labelBuildStatus.Text = 'Checking...'
            $labelBuildStatus.ForeColor = [Drawing.Color]::DarkOrange
        }
        'Approved' {
            $labelBuildStatus.Text = 'APPROVED'
            $labelBuildStatus.ForeColor = [Drawing.Color]::ForestGreen
        }
        'Denied' {
            $labelBuildStatus.Text = 'NOT APPROVED'
            $labelBuildStatus.ForeColor = [Drawing.Color]::Firebrick
        }
    }
}
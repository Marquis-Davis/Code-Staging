# Keep all three PictureBoxes inside the status panel
foreach ($box in @($pictureBoxBuildChecking, $pictureBoxBuildApproved, $pictureBoxBuildDenied)) {
    $box.Parent = $panelBuildStatus
    $box.Location = [System.Drawing.Point]::new(9, 2)
}

Set-BuildSegmentStatus -Status 'Checking'
$pictureBoxBuildChecking.BringToFront()
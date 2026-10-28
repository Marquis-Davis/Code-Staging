[System.Windows.Forms.MessageBox]::Show(
    "Visible: $($pictureBoxBuildChecking.Visible)`nImage Loaded: $($null -ne $pictureBoxBuildChecking.Image)`nParent: $($pictureBoxBuildChecking.Parent.Name)"
)
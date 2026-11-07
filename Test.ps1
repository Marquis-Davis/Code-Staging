$user = if ($textboxUsername -and $textboxUsername.Text.Trim()) {
    $textboxUsername.Text.Trim()
}
else {
    'Not entered'
}
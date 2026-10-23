$form.MinimumSize = [System.Drawing.Size]::new($form.Width, 400)
$form.MaximumSize = [System.Drawing.Size]::new($form.Width, $form.Height)

$form.Add_Resize({
    if ($form.Width -ne $form.MaximumSize.Width) {
        $form.Width = $form.MaximumSize.Width
    }
})